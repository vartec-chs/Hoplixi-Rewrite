import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../interfaces/encryptor.dart';
import 'key_derivation_service.dart';

// Re-export cipher for use in this file
import 'package:cryptography/cryptography.dart';

import '../models/exceptions.dart';
import '../models/header.dart';
import '../models/params.dart';
import '../models/streaming.dart';

export '../models/exceptions.dart';
export '../models/header.dart';

/// Encryptor implementation with archive support.
///
/// Provides encryption for files and directories with compression:
/// - Files: gzip → encrypt
/// - Directories: zip → gzip → encrypt
///
/// Uses XChaCha20-Poly1305 for encryption and Argon2id for key derivation.
class ArchiveEncryptor implements IEncryptor {
  /// Default chunk size for streaming operations (1 MB).
  static const int defaultChunkSize = 1024 * 1024;
  static const int fileSizeThresholdForIsolate = 100 * 1024 * 1024; // 100 MB

  /// Chunk size for streaming.
  final int _chunkSize;

  /// Creates an archive encryptor with optional custom chunk size.
  ArchiveEncryptor({int? chunkSize})
    : _chunkSize = chunkSize ?? defaultChunkSize;

  @override
  Future<EncryptionOperationResult> encrypt({
    required String inputPath,
    required String outputPath,
    required String password,
    String? customUuid,
    ProgressCallback? onProgress,
    bool enableGzip = true,
    bool useIsolate = true,
  }) async {
    final inputEntity = FileSystemEntity.typeSync(inputPath);

    if (inputEntity == FileSystemEntityType.notFound) {
      throw EncryptionExceptionArchive('Input path not found: $inputPath');
    }

    final isDirectory = inputEntity == FileSystemEntityType.directory;

    // Check size for isolate decision
    int originalSize;
    if (isDirectory) {
      originalSize = await _getDirectorySize(Directory(inputPath));
    } else {
      originalSize = await File(inputPath).length();
    }

    final isIsolate =
        useIsolate || (originalSize > fileSizeThresholdForIsolate); // 100 MB

    if (isIsolate) {
      final receivePort = ReceivePort();
      final params = EncryptionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
        customUuid: customUuid,
        chunkSize: _chunkSize,
        sendPort: receivePort.sendPort,
        originalSize: originalSize,
        enableGzip: enableGzip,
      );

      await Isolate.spawn(_encryptEntry, params);

      final completer = Completer<EncryptionOperationResult>();
      final subscription = receivePort.listen((message) {
        if (message is List) {
          onProgress?.call(message[0] as int, message[1] as int);
        } else if (message is EncryptionOperationResult) {
          completer.complete(message);
        } else if (message is Exception || message is Error) {
          completer.completeError(message);
        }
      });

      try {
        return await completer.future;
      } finally {
        subscription.cancel();
        receivePort.close();
      }
    } else {
      final params = EncryptionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
        customUuid: customUuid,
        chunkSize: _chunkSize,
        originalSize: originalSize,
        enableGzip: enableGzip,
      );
      return _encryptImpl(params, onProgress: onProgress);
    }
  }

  static void _encryptEntry(EncryptionParams params) async {
    try {
      final result = await _encryptImpl(params);
      params.sendPort?.send(result);
    } catch (e) {
      params.sendPort?.send(e);
    }
  }

  static Future<EncryptionOperationResult> _encryptImpl(
    EncryptionParams params, {
    ProgressCallback? onProgress,
  }) async {
    final inputPath = params.inputPath;
    final outputPath = params.outputPath;
    final password = params.password;
    final customUuid = params.customUuid;
    final chunkSize = params.chunkSize;
    final sendPort = params.sendPort;
    final enableGzip = params.enableGzip;

    void reportProgress(int current, int total) {
      if (onProgress != null) {
        onProgress(current, total);
      }
      if (sendPort != null) {
        sendPort.send([current, total]);
      }
    }

    final inputEntity = FileSystemEntity.typeSync(inputPath);
    final isDirectory = inputEntity == FileSystemEntityType.directory;
    final originalName = p.basename(inputPath);
    final originalExtension = isDirectory
        ? ''
        : p.extension(inputPath).replaceFirst('.', '');

    // Create temp directory for intermediate steps
    final tempDir = await Directory.systemTemp.createTemp('enc_');
    File? tempZipFile;

    try {
      int originalSize = params.originalSize;

      // We will create a stream that yields the compressed data
      Stream<List<int>> compressedStream;
      int compressedSize = 0;

      if (isDirectory) {
        // originalSize is already calculated and passed in params

        // 1. Create ZIP file (using ZipFileEncoder to avoid memory issues)
        final tempZipPath = p.join(tempDir.path, 'data.zip');
        final encoder = ZipFileEncoder();
        encoder.create(tempZipPath);

        // Add directory content recursively
        await encoder.addDirectory(Directory(inputPath), includeDirName: false);
        encoder.close();

        tempZipFile = File(tempZipPath);
        final zipSize = await tempZipFile.length();

        // Report progress for Zipping phase (approximate)
        reportProgress(zipSize ~/ 2, originalSize);

        // 2. Gzip the ZIP file (if enabled)
        if (enableGzip) {
          final tempGzipPath = p.join(tempDir.path, 'data.tar.gz');
          final gzipFile = File(tempGzipPath);

          final zipInput = tempZipFile.openRead();
          final gzipOutput = gzipFile.openWrite();

          await zipInput.transform(gzip.encoder).pipe(gzipOutput);

          compressedSize = await gzipFile.length();
          compressedStream = gzipFile.openRead();

          // Report progress
          reportProgress(originalSize ~/ 1.5, originalSize);
        } else {
          compressedSize = zipSize;
          compressedStream = tempZipFile.openRead();
        }
      } else {
        // File case
        final file = File(inputPath);
        // originalSize passed in params

        if (enableGzip) {
          // Just Gzip the file to a temp file to get size
          final tempGzipPath = p.join(tempDir.path, 'data.gz');
          final gzipFile = File(tempGzipPath);

          final input = file.openRead();
          final gzipOutput = gzipFile.openWrite();

          await input.transform(gzip.encoder).pipe(gzipOutput);

          compressedSize = await gzipFile.length();
          compressedStream = gzipFile.openRead();
        } else {
          compressedSize = originalSize;
          compressedStream = file.openRead();
        }
      }

      // Create header
      final header = customUuid != null
          ? ArchiveEncryptionHeader(
              uuid: customUuid,
              originalName: originalName,
              wasDirectory: isDirectory,
              originalExtension: originalExtension,
              originalSize: originalSize,
              compressedSize: compressedSize,
              isCompressed: enableGzip,
            )
          : ArchiveEncryptionHeader.create(
              originalName: originalName,
              wasDirectory: isDirectory,
              originalExtension: originalExtension,
              originalSize: originalSize,
              compressedSize: compressedSize,
              isCompressed: enableGzip,
            );

      // Encrypt the compressed stream
      final result = await _encryptStreamWithHeader(
        inputStream: compressedStream,
        outputPath: outputPath,
        password: password,
        header: header,
        fileSize: compressedSize,
        chunkSize: chunkSize,
        onProgress: reportProgress,
      );

      return EncryptionOperationResult(
        uuid: header.uuid,
        outputPath: outputPath,
        originalName: originalName,
        wasDirectory: isDirectory,
        originalExtension: originalExtension,
        bytesWritten: result,
        originalSize: originalSize,
      );
    } finally {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  @override
  Future<DecryptionOperationResult> decrypt({
    required String inputPath,
    required String outputPath,
    required String password,
    ProgressCallback? onProgress,
    bool useIsolate = true,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw DecryptionExceptionArchive('Input file not found: $inputPath');
    }

    final fileSize = await inputFile.length();
    final isIsolate =
        useIsolate || (fileSize > fileSizeThresholdForIsolate); // 100 MB

    if (isIsolate) {
      final receivePort = ReceivePort();
      final params = DecryptionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
        sendPort: receivePort.sendPort,
      );

      await Isolate.spawn(_decryptEntry, params);

      final completer = Completer<DecryptionOperationResult>();
      final subscription = receivePort.listen((message) {
        if (message is List) {
          onProgress?.call(message[0] as int, message[1] as int);
        } else if (message is DecryptionOperationResult) {
          completer.complete(message);
        } else if (message is Exception || message is Error) {
          completer.completeError(message);
        }
      });

      try {
        return await completer.future;
      } finally {
        subscription.cancel();
        receivePort.close();
      }
    } else {
      final params = DecryptionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
      );
      return _decryptImpl(params, onProgress: onProgress);
    }
  }

  static void _decryptEntry(DecryptionParams params) async {
    try {
      final result = await _decryptImpl(params);
      params.sendPort?.send(result);
    } catch (e) {
      params.sendPort?.send(e);
    }
  }

  static Future<DecryptionOperationResult> _decryptImpl(
    DecryptionParams params, {
    ProgressCallback? onProgress,
  }) async {
    final inputPath = params.inputPath;
    final outputPath = params.outputPath;
    final password = params.password;
    final sendPort = params.sendPort;

    void reportProgress(int current, int total) {
      if (onProgress != null) {
        onProgress(current, total);
      }
      if (sendPort != null) {
        sendPort.send([current, total]);
      }
    }

    // Create temp directory for decryption
    final tempDir = await Directory.systemTemp.createTemp('dec_');
    final tempCompressedPath = p.join(tempDir.path, 'decrypted.gz');

    try {
      // Decrypt and get header
      final header = await _decryptWithArchiveHeader(
        inputPath: inputPath,
        outputPath: tempCompressedPath,
        password: password,
        onProgress: reportProgress,
      );

      int bytesWritten;
      String finalOutputPath;

      if (header.wasDirectory) {
        // Decompress gzip -> unzip
        finalOutputPath = p.join(outputPath, header.originalName);

        // Ensure output directory exists (handles empty directories too)
        await Directory(finalOutputPath).create(recursive: true);

        final tempZipPath = p.join(tempDir.path, 'decrypted.zip');

        if (header.isCompressed) {
          final compressedInput = File(tempCompressedPath).openRead();
          final zipOutput = File(tempZipPath).openWrite();
          await compressedInput.transform(gzip.decoder).pipe(zipOutput);
        } else {
          await File(tempCompressedPath).copy(tempZipPath);
        }

        // 2. Unzip using ZipDecoder with InputFileStream (memory safe)
        final inputStream = InputFileStream(tempZipPath);
        final archive = ZipDecoder().decodeStream(inputStream);

        // Extract archive
        for (final file in archive.files) {
          if (file.isFile) {
            final outputStream = OutputFileStream(
              p.join(finalOutputPath, file.name),
            );
            file.writeContent(outputStream);
            outputStream.close();
          } else {
            await Directory(
              p.join(finalOutputPath, file.name),
            ).create(recursive: true);
          }
        }
        await inputStream.close();
        bytesWritten = header.originalSize; // Approximate
      } else {
        // Decompress gzip only
        final ext = header.originalExtension.isNotEmpty
            ? '.${header.originalExtension}'
            : '';
        finalOutputPath = p.join(outputPath, '${header.originalName}$ext');

        // Ensure we don't duplicate extension
        if (header.originalName.endsWith(ext)) {
          finalOutputPath = p.join(outputPath, header.originalName);
        }

        // Ensure parent directory exists
        await Directory(p.dirname(finalOutputPath)).create(recursive: true);

        final compressedInput = File(tempCompressedPath).openRead();
        final output = File(finalOutputPath).openWrite();

        if (header.isCompressed) {
          await compressedInput.transform(gzip.decoder).pipe(output);
        } else {
          await File(tempCompressedPath).openRead().pipe(output);
        }
        bytesWritten = await File(finalOutputPath).length();
      }

      return DecryptionOperationResult(
        uuid: header.uuid,
        outputPath: finalOutputPath,
        originalName: header.originalName,
        wasDirectory: header.wasDirectory,
        bytesWritten: bytesWritten,
      );
    } finally {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  @override
  Future<Uint8List> encryptBytes({
    required Uint8List data,
    required String password,
    String? customUuid,
    bool enableGzip = true,
  }) async {
    // Compress with gzip
    final compressed = enableGzip ? GZipEncoder().encode(data) : data;

    // Create header
    final header = ArchiveEncryptionHeader(
      uuid: customUuid ?? const Uuid().v4(),
      originalName: 'data',
      wasDirectory: false,
      originalExtension: '',
      originalSize: data.length,
      compressedSize: compressed.length,
      isCompressed: enableGzip,
    );

    // Derive key pair
    final keyPair = await KeyDerivationService.deriveKeyPair(
      password: password,
    );

    // Encrypt
    final cipher = Xchacha20.poly1305Aead();
    final headerBytes = header.toBytes();

    // Encrypt header
    final headerNonce = KeyDerivationService.generateSecureRandomBytes(24);
    final headerBox = await cipher.encrypt(
      headerBytes,
      secretKey: keyPair.encryptionKey,
      nonce: headerNonce,
    );

    // Encrypt data
    final dataNonce = KeyDerivationService.generateSecureRandomBytes(24);
    final dataBox = await cipher.encrypt(
      compressed,
      secretKey: keyPair.encryptionKey,
      nonce: dataNonce,
    );

    // Build output:
    // [Magic "AENC" (4 bytes)]
    // [Version (1 byte)]
    // [Salt (16 bytes)]
    // [Header Nonce (24 bytes)]
    // [Header Length (4 bytes)]
    // [Encrypted Header]
    // [Header Auth Tag (16 bytes)]
    // [Data Nonce (24 bytes)]
    // [Encrypted Data]
    // [Data Auth Tag (16 bytes)]
    // [HMAC (32 bytes)]

    final outputSize =
        4 + // magic
        1 + // version
        16 + // salt
        24 + // header nonce
        4 + // header length
        headerBox.cipherText.length +
        16 + // header auth tag
        24 + // data nonce
        dataBox.cipherText.length +
        16 + // data auth tag
        32; // hmac

    final output = Uint8List(outputSize);
    final view = ByteData.view(output.buffer);
    var offset = 0;

    // Magic "AENC"
    output.setRange(offset, offset + 4, [0x41, 0x45, 0x4E, 0x43]);
    offset += 4;

    // Version
    output[offset++] = 1;

    // Salt
    output.setRange(offset, offset + 16, keyPair.salt);
    offset += 16;

    // Header nonce
    output.setRange(offset, offset + 24, headerNonce);
    offset += 24;

    // Header length
    view.setUint32(offset, headerBox.cipherText.length, Endian.big);
    offset += 4;

    // Encrypted header
    output.setRange(
      offset,
      offset + headerBox.cipherText.length,
      headerBox.cipherText,
    );
    offset += headerBox.cipherText.length;

    // Header auth tag
    output.setRange(offset, offset + 16, headerBox.mac.bytes);
    offset += 16;

    // Data nonce
    output.setRange(offset, offset + 24, dataNonce);
    offset += 24;

    // Encrypted data
    output.setRange(
      offset,
      offset + dataBox.cipherText.length,
      dataBox.cipherText,
    );
    offset += dataBox.cipherText.length;

    // Data auth tag
    output.setRange(offset, offset + 16, dataBox.mac.bytes);
    offset += 16;

    // Calculate HMAC over everything before it
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      output.sublist(0, offset),
      secretKey: keyPair.hmacKey,
    );
    output.setRange(offset, offset + 32, mac.bytes);

    return output;
  }

  @override
  Future<Uint8List> decryptBytes({
    required Uint8List encryptedData,
    required String password,
  }) async {
    if (encryptedData.length < 4 + 1 + 16 + 24 + 4 + 16 + 24 + 16 + 32) {
      throw const DecryptionExceptionArchive('Encrypted data too short');
    }

    final view = ByteData.view(
      encryptedData.buffer,
      encryptedData.offsetInBytes,
    );
    var offset = 0;

    // Verify magic
    if (encryptedData[0] != 0x41 ||
        encryptedData[1] != 0x45 ||
        encryptedData[2] != 0x4E ||
        encryptedData[3] != 0x43) {
      throw const DecryptionExceptionArchive('Invalid magic bytes');
    }
    offset += 4;

    // Version
    final version = encryptedData[offset++];
    if (version != 1) {
      throw DecryptionExceptionArchive('Unsupported version: $version');
    }

    // Salt
    final salt = encryptedData.sublist(offset, offset + 16);
    offset += 16;

    // Derive key pair
    final keyPair = await KeyDerivationService.deriveKeyPairWithSalt(
      password: password,
      salt: Uint8List.fromList(salt),
    );

    // Verify HMAC
    final hmac = Hmac.sha256();
    final storedHmac = encryptedData.sublist(encryptedData.length - 32);
    final calculatedMac = await hmac.calculateMac(
      encryptedData.sublist(0, encryptedData.length - 32),
      secretKey: keyPair.hmacKey,
    );

    if (!_constantTimeEquals(
      Uint8List.fromList(calculatedMac.bytes),
      Uint8List.fromList(storedHmac),
    )) {
      throw const AuthenticationExceptionArchive('HMAC verification failed');
    }

    // Header nonce
    final headerNonce = encryptedData.sublist(offset, offset + 24);
    offset += 24;

    // Header length
    final headerLength = view.getUint32(offset, Endian.big);
    offset += 4;

    // Encrypted header
    final encryptedHeader = encryptedData.sublist(
      offset,
      offset + headerLength,
    );
    offset += headerLength;

    // Header auth tag
    final headerAuthTag = encryptedData.sublist(offset, offset + 16);
    offset += 16;

    // Decrypt header
    final cipher = Xchacha20.poly1305Aead();
    final headerBox = SecretBox(
      encryptedHeader,
      nonce: headerNonce,
      mac: Mac(headerAuthTag),
    );

    List<int> headerBytes;
    try {
      headerBytes = await cipher.decrypt(
        headerBox,
        secretKey: keyPair.encryptionKey,
      );
    } on SecretBoxAuthenticationError {
      throw const AuthenticationExceptionArchive('Header decryption failed');
    }

    // Parse header
    final header = ArchiveEncryptionHeader.fromBytes(
      Uint8List.fromList(headerBytes),
    );

    // Data nonce
    final dataNonce = encryptedData.sublist(offset, offset + 24);
    offset += 24;

    // Calculate encrypted data length
    final encryptedDataLength =
        encryptedData.length - offset - 16 - 32; // minus auth tag and hmac
    final encryptedContent = encryptedData.sublist(
      offset,
      offset + encryptedDataLength,
    );
    offset += encryptedDataLength;

    // Data auth tag
    final dataAuthTag = encryptedData.sublist(offset, offset + 16);

    // Decrypt data
    final dataBox = SecretBox(
      encryptedContent,
      nonce: dataNonce,
      mac: Mac(dataAuthTag),
    );

    List<int> compressedData;
    try {
      compressedData = await cipher.decrypt(
        dataBox,
        secretKey: keyPair.encryptionKey,
      );
    } on SecretBoxAuthenticationError {
      throw const AuthenticationExceptionArchive('Data decryption failed');
    }

    // Decompress
    final decompressed = header.isCompressed
        ? GZipDecoder().decodeBytes(compressedData)
        : compressedData;

    return Uint8List.fromList(decompressed);
  }

  /// Reads the header from an encrypted file without decrypting the content.
  Future<ArchiveEncryptionHeader> readHeader({
    required String inputPath,
    required String password,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw EncryptionExceptionArchive('Input file not found: $inputPath');
    }
    final handle = await inputFile.open();
    DerivedKeyPair? keyPair;

    try {
      // Read and verify magic
      final magic = await _readExactBytes(handle, 4);
      if (magic[0] != 0x41 ||
          magic[1] != 0x45 ||
          magic[2] != 0x4E ||
          magic[3] != 0x43) {
        throw const DecryptionExceptionArchive('Invalid magic bytes');
      }

      // Version
      final versionBytes = await _readExactBytes(handle, 1);
      if (versionBytes[0] != 1) {
        throw DecryptionExceptionArchive(
          'Unsupported version: ${versionBytes[0]}',
        );
      }

      // Salt
      final salt = await _readExactBytes(handle, 16);

      // Derive key pair
      keyPair = await KeyDerivationService.deriveKeyPairWithSalt(
        password: password,
        salt: salt,
      );

      // Read header nonce
      final headerNonce = await _readExactBytes(handle, 24);

      // Read header length
      final headerLengthBytes = await _readExactBytes(handle, 4);
      final headerLength = ByteData.view(
        headerLengthBytes.buffer,
        headerLengthBytes.offsetInBytes,
      ).getUint32(0, Endian.big);

      // Validate header length
      if (headerLength > 10000) {
        throw const DecryptionExceptionArchive('Header length too large');
      }

      // Read encrypted header
      final encryptedHeader = await _readExactBytes(handle, headerLength);

      // Read header auth tag
      final headerAuthTag = await _readExactBytes(handle, 16);

      // Decrypt header
      final cipher = Xchacha20.poly1305Aead();
      final headerBox = SecretBox(
        encryptedHeader,
        nonce: headerNonce,
        mac: Mac(headerAuthTag),
      );

      List<int> headerBytes;
      try {
        headerBytes = await cipher.decrypt(
          headerBox,
          secretKey: keyPair.encryptionKey,
        );
      } on SecretBoxAuthenticationError {
        throw const AuthenticationExceptionArchive('Header decryption failed');
      }

      return ArchiveEncryptionHeader.fromBytes(Uint8List.fromList(headerBytes));
    } finally {
      await handle.close();
      keyPair?.destroy();
    }
  }

  /// Gets total size of a directory.
  static Future<int> _getDirectorySize(Directory dir) async {
    var size = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Encrypts compressed stream with archive header using streaming.
  ///
  /// Processes data in chunks to avoid loading entire file into memory.
  /// Uses streaming HMAC for incremental calculation.
  static Future<int> _encryptStreamWithHeader({
    required Stream<List<int>> inputStream,
    required String outputPath,
    required String password,
    required ArchiveEncryptionHeader header,
    required int fileSize,
    required int chunkSize,
    ProgressCallback? onProgress,
  }) async {
    // Derive key pair
    final keyPair = await KeyDerivationService.deriveKeyPair(
      password: password,
    );
    final cipher = Xchacha20.poly1305Aead();

    // Open output file
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();
    StreamingHmacArchive? hmacSink;
    bool success = false;

    try {
      // Create streaming HMAC (no memory accumulation)
      hmacSink = await StreamingHmacArchive.create(keyPair.hmacKey);

      // Magic "AENC"
      final magic = Uint8List.fromList([0x41, 0x45, 0x4E, 0x43]);
      outputSink.add(magic);
      hmacSink.add(magic);

      // Version
      final version = Uint8List.fromList([1]);
      outputSink.add(version);
      hmacSink.add(version);

      // Salt
      outputSink.add(keyPair.salt);
      hmacSink.add(keyPair.salt);

      // Encrypt header
      final headerBytes = header.toBytes();
      final headerNonce = KeyDerivationService.generateSecureRandomBytes(24);
      final headerBox = await cipher.encrypt(
        headerBytes,
        secretKey: keyPair.encryptionKey,
        nonce: headerNonce,
      );

      // Header nonce
      outputSink.add(headerNonce);
      hmacSink.add(headerNonce);

      // Header length
      final headerLengthBytes = Uint8List(4);
      ByteData.view(
        headerLengthBytes.buffer,
      ).setUint32(0, headerBox.cipherText.length, Endian.big);
      outputSink.add(headerLengthBytes);
      hmacSink.add(headerLengthBytes);

      // Encrypted header
      final headerCiphertext = Uint8List.fromList(headerBox.cipherText);
      outputSink.add(headerCiphertext);
      hmacSink.add(headerCiphertext);

      // Header auth tag
      final headerAuthTag = Uint8List.fromList(headerBox.mac.bytes);
      outputSink.add(headerAuthTag);
      hmacSink.add(headerAuthTag);

      // Chunk size field
      final chunkSizeBytes = Uint8List(4);
      ByteData.view(chunkSizeBytes.buffer).setUint32(0, chunkSize, Endian.big);
      outputSink.add(chunkSizeBytes);
      hmacSink.add(chunkSizeBytes);

      // Chunk count
      final chunkCount = fileSize == 0 ? 0 : ((fileSize - 1) ~/ chunkSize) + 1;
      final chunkCountBytes = Uint8List(8);
      ByteData.view(chunkCountBytes.buffer).setInt64(0, chunkCount, Endian.big);
      outputSink.add(chunkCountBytes);
      hmacSink.add(chunkCountBytes);

      // Process stream in chunks
      final buffer = ChunkBufferArchive(chunkSize);
      var bytesProcessed = 0;
      var chunksSinceFlush = 0;
      const flushInterval =
          8; // Flush every 8 chunks (~8MB) to prevent memory buildup

      await for (final data in inputStream) {
        buffer.addAll(data);

        while (buffer.hasFullChunk) {
          final chunk = buffer.takeChunk();
          await _writeEncryptedChunk(
            chunkData: chunk,
            encryptionKey: keyPair.encryptionKey,
            cipher: cipher,
            outputSink: outputSink,
            hmacSink: hmacSink,
          );

          bytesProcessed += chunk.length;
          onProgress?.call(bytesProcessed, fileSize);

          // Clear sensitive data
          _clearBytes(chunk);

          // Flush periodically
          chunksSinceFlush++;
          if (chunksSinceFlush >= flushInterval) {
            await outputSink.flush();
            chunksSinceFlush = 0;
          }
        }
      }

      // Process remaining data
      if (buffer.isNotEmpty) {
        final remainingData = buffer.takeRemaining();

        await _writeEncryptedChunk(
          chunkData: remainingData,
          encryptionKey: keyPair.encryptionKey,
          cipher: cipher,
          outputSink: outputSink,
          hmacSink: hmacSink,
        );

        bytesProcessed += remainingData.length;
        onProgress?.call(bytesProcessed, fileSize);

        // Clear sensitive data
        _clearBytes(remainingData);
      }

      // Finalize streaming HMAC
      final finalHmac = await hmacSink.finalize();
      outputSink.add(finalHmac.bytes);

      await outputSink.flush();
      success = true;

      return await outputFile.length();
    } catch (e) {
      // Logic handled in finally
      rethrow;
    } finally {
      await outputSink.close();
      hmacSink?.clear();
      keyPair.destroy();
      if (!success && await outputFile.exists()) {
        try {
          await outputFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Encrypts a single chunk and writes to output.
  static Future<void> _writeEncryptedChunk({
    required Uint8List chunkData,
    required SecretKey encryptionKey,
    required StreamingCipher cipher,
    required IOSink outputSink,
    required StreamingHmacArchive hmacSink,
  }) async {
    // Generate unique nonce for this chunk
    final chunkNonce = KeyDerivationService.generateSecureRandomBytes(24);

    // Encrypt chunk
    final chunkBox = await cipher.encrypt(
      chunkData,
      secretKey: encryptionKey,
      nonce: chunkNonce,
    );

    // Write: nonce + ciphertext + auth tag
    // Use cipherText and mac.bytes directly without copying
    outputSink.add(chunkNonce);
    outputSink.add(chunkBox.cipherText);
    outputSink.add(chunkBox.mac.bytes);

    // Add to streaming HMAC (no memory accumulation)
    hmacSink.add(chunkNonce);
    hmacSink.add(chunkBox.cipherText);
    hmacSink.add(chunkBox.mac.bytes);
  }

  /// Decrypts file and returns archive header using streaming.
  ///
  /// Processes file in chunks to avoid loading entire file into memory.
  /// Uses streaming HMAC for incremental verification.
  static Future<ArchiveEncryptionHeader> _decryptWithArchiveHeader({
    required String inputPath,
    required String outputPath,
    required String password,
    ProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    final handle = await inputFile.open();
    IOSink? outputSink;
    File? outputFile;
    bool success = false;
    DerivedKeyPair? keyPair;
    StreamingHmacArchive? hmacSink;

    try {
      // Read and verify magic
      final magic = await _readExactBytes(handle, 4);
      if (magic[0] != 0x41 ||
          magic[1] != 0x45 ||
          magic[2] != 0x4E ||
          magic[3] != 0x43) {
        throw const DecryptionExceptionArchive('Invalid magic bytes');
      }

      // Version
      final versionBytes = await _readExactBytes(handle, 1);
      if (versionBytes[0] != 1) {
        throw DecryptionExceptionArchive(
          'Unsupported version: ${versionBytes[0]}',
        );
      }

      // Salt
      final salt = await _readExactBytes(handle, 16);

      // Derive key pair
      keyPair = await KeyDerivationService.deriveKeyPairWithSalt(
        password: password,
        salt: salt,
      );

      // Create streaming HMAC for verification
      hmacSink = await StreamingHmacArchive.create(keyPair.hmacKey);

      // Add already-read data to HMAC
      hmacSink.add(magic);
      hmacSink.add(versionBytes);
      hmacSink.add(salt);

      // Read header nonce
      final headerNonce = await _readExactBytes(handle, 24);
      hmacSink.add(headerNonce);

      // Read header length
      final headerLengthBytes = await _readExactBytes(handle, 4);
      hmacSink.add(headerLengthBytes);
      final headerLength = ByteData.view(
        headerLengthBytes.buffer,
        headerLengthBytes.offsetInBytes,
      ).getUint32(0, Endian.big);

      // Validate header length
      if (headerLength > 10000) {
        throw const DecryptionExceptionArchive('Header length too large');
      }

      // Read encrypted header
      final encryptedHeader = await _readExactBytes(handle, headerLength);
      hmacSink.add(encryptedHeader);

      // Read header auth tag
      final headerAuthTag = await _readExactBytes(handle, 16);
      hmacSink.add(headerAuthTag);

      // Decrypt header
      final cipher = Xchacha20.poly1305Aead();
      final headerBox = SecretBox(
        encryptedHeader,
        nonce: headerNonce,
        mac: Mac(headerAuthTag),
      );

      List<int> headerBytes;
      try {
        headerBytes = await cipher.decrypt(
          headerBox,
          secretKey: keyPair.encryptionKey,
        );
      } on SecretBoxAuthenticationError {
        throw const AuthenticationExceptionArchive('Header decryption failed');
      }

      final header = ArchiveEncryptionHeader.fromBytes(
        Uint8List.fromList(headerBytes),
      );

      // Read chunk size
      final chunkSizeBytes = await _readExactBytes(handle, 4);
      hmacSink.add(chunkSizeBytes);
      final chunkSize = ByteData.view(
        chunkSizeBytes.buffer,
        chunkSizeBytes.offsetInBytes,
      ).getUint32(0, Endian.big);

      // Read chunk count
      final chunkCountBytes = await _readExactBytes(handle, 8);
      hmacSink.add(chunkCountBytes);
      final chunkCount = ByteData.view(
        chunkCountBytes.buffer,
        chunkCountBytes.offsetInBytes,
      ).getInt64(0, Endian.big);

      // Open output file for streaming write
      outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      outputSink = outputFile.openWrite();

      var bytesWritten = 0;

      // Process each chunk
      for (var i = 0; i < chunkCount; i++) {
        // Read chunk nonce
        final chunkNonce = await _readExactBytes(handle, 24);
        hmacSink.add(chunkNonce);

        // Calculate expected chunk data size
        // For the last chunk, it may be smaller than chunkSize
        final isLastChunk = i == chunkCount - 1;
        final expectedPlaintextSize = isLastChunk
            ? (header.compressedSize % chunkSize == 0
                  ? chunkSize
                  : header.compressedSize % chunkSize)
            : chunkSize;

        // Read encrypted chunk (same size as plaintext for stream cipher)
        final encryptedChunk = await _readExactBytes(
          handle,
          expectedPlaintextSize,
        );
        hmacSink.add(encryptedChunk);

        // Read chunk auth tag
        final chunkAuthTag = await _readExactBytes(handle, 16);
        hmacSink.add(chunkAuthTag);

        // Decrypt chunk
        final chunkBox = SecretBox(
          encryptedChunk,
          nonce: chunkNonce,
          mac: Mac(chunkAuthTag),
        );

        List<int> decryptedChunk;
        try {
          decryptedChunk = await cipher.decrypt(
            chunkBox,
            secretKey: keyPair.encryptionKey,
          );
        } on SecretBoxAuthenticationError {
          throw const AuthenticationExceptionArchive('Chunk decryption failed');
        }

        // Write decrypted chunk to output
        outputSink.add(decryptedChunk);
        bytesWritten += decryptedChunk.length;

        onProgress?.call(bytesWritten, header.compressedSize);
      }

      await outputSink.flush();

      // Verify final HMAC
      final storedHmac = await _readExactBytes(handle, 32);
      final calculatedMac = await hmacSink.finalize();

      if (!_constantTimeEquals(
        Uint8List.fromList(calculatedMac.bytes),
        storedHmac,
      )) {
        throw const AuthenticationExceptionArchive('HMAC verification failed');
      }

      success = true;
      return header;
    } catch (e) {
      // Logic handled in finally
      rethrow;
    } finally {
      await handle.close();
      if (outputSink != null) await outputSink.close();
      keyPair?.destroy();
      hmacSink?.clear();
      if (!success && outputFile != null && await outputFile.exists()) {
        try {
          await outputFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Reads exact number of bytes from file handle.
  static Future<Uint8List> _readExactBytes(
    RandomAccessFile handle,
    int length,
  ) async {
    final bytes = await handle.read(length);
    if (bytes.length != length) {
      throw DecryptionExceptionArchive(
        'Unexpected end of file: expected $length bytes, got ${bytes.length}',
      );
    }
    return bytes;
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Best-effort clearing of sensitive bytes.
  static void _clearBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
