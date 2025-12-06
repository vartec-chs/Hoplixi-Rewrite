import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../interfaces/encryptor.dart';
import 'key_derivation_service.dart';

// Re-export cipher for use in this file
import 'package:cryptography/cryptography.dart';

/// Exception thrown during encryption operations.
class EncryptionExceptionArchive implements Exception {
  /// Error message.
  final String message;

  /// Creates an encryption exception.
  const EncryptionExceptionArchive(this.message);

  @override
  String toString() => 'EncryptionExceptionArchive: $message';
}

/// Exception thrown during decryption operations.
class DecryptionExceptionArchive implements Exception {
  /// Error message.
  final String message;

  /// Creates a decryption exception.
  const DecryptionExceptionArchive(this.message);

  @override
  String toString() => 'DecryptionExceptionArchive: $message';
}

/// Exception thrown when authentication fails.
class AuthenticationExceptionArchive implements Exception {
  /// Error message.
  final String message;

  /// Creates an authentication exception.
  const AuthenticationExceptionArchive(this.message);

  @override
  String toString() => 'AuthenticationExceptionArchive: $message';
}

/// Extended header for archive encryption.
///
/// Contains additional metadata about the original content.
class ArchiveEncryptionHeader {
  /// Unique identifier for the encrypted content.
  final String uuid;

  /// Original file or directory name.
  final String originalName;

  /// Whether the source was a directory.
  final bool wasDirectory;

  /// Original file extension (if file).
  final String originalExtension;

  /// Original size before compression.
  final int originalSize;

  /// Size after compression (before encryption).
  final int compressedSize;

  const ArchiveEncryptionHeader({
    required this.uuid,
    required this.originalName,
    required this.wasDirectory,
    required this.originalExtension,
    required this.originalSize,
    required this.compressedSize,
  });

  /// Serializes the header to bytes.
  Uint8List toBytes() {
    final uuidBytes = utf8.encode(uuid);
    final nameBytes = utf8.encode(originalName);
    final extBytes = utf8.encode(originalExtension);

    // Format:
    // [UUID length (1 byte)]
    // [UUID (variable)]
    // [Name length (2 bytes)]
    // [Name (variable)]
    // [Extension length (1 byte)]
    // [Extension (variable)]
    // [wasDirectory (1 byte)]
    // [originalSize (8 bytes)]
    // [compressedSize (8 bytes)]

    final totalLength =
        1 +
        uuidBytes.length +
        2 +
        nameBytes.length +
        1 +
        extBytes.length +
        1 +
        8 +
        8;

    final bytes = Uint8List(totalLength);
    final view = ByteData.view(bytes.buffer);
    var offset = 0;

    // UUID length and data
    bytes[offset++] = uuidBytes.length;
    bytes.setRange(offset, offset + uuidBytes.length, uuidBytes);
    offset += uuidBytes.length;

    // Name length (2 bytes) and data
    view.setUint16(offset, nameBytes.length, Endian.big);
    offset += 2;
    bytes.setRange(offset, offset + nameBytes.length, nameBytes);
    offset += nameBytes.length;

    // Extension length and data
    bytes[offset++] = extBytes.length;
    bytes.setRange(offset, offset + extBytes.length, extBytes);
    offset += extBytes.length;

    // wasDirectory
    bytes[offset++] = wasDirectory ? 1 : 0;

    // originalSize
    view.setInt64(offset, originalSize, Endian.big);
    offset += 8;

    // compressedSize
    view.setInt64(offset, compressedSize, Endian.big);

    return bytes;
  }

  /// Deserializes the header from bytes.
  factory ArchiveEncryptionHeader.fromBytes(Uint8List bytes) {
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;

    // UUID
    final uuidLength = bytes[offset++];
    final uuid = utf8.decode(bytes.sublist(offset, offset + uuidLength));
    offset += uuidLength;

    // Name
    final nameLength = view.getUint16(offset, Endian.big);
    offset += 2;
    final originalName = utf8.decode(
      bytes.sublist(offset, offset + nameLength),
    );
    offset += nameLength;

    // Extension
    final extLength = bytes[offset++];
    final originalExtension = utf8.decode(
      bytes.sublist(offset, offset + extLength),
    );
    offset += extLength;

    // wasDirectory
    final wasDirectory = bytes[offset++] == 1;

    // originalSize
    final originalSize = view.getInt64(offset, Endian.big);
    offset += 8;

    // compressedSize
    final compressedSize = view.getInt64(offset, Endian.big);

    return ArchiveEncryptionHeader(
      uuid: uuid,
      originalName: originalName,
      wasDirectory: wasDirectory,
      originalExtension: originalExtension,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }

  /// Creates a new header with a generated UUID.
  factory ArchiveEncryptionHeader.create({
    required String originalName,
    required bool wasDirectory,
    required String originalExtension,
    required int originalSize,
    required int compressedSize,
  }) {
    return ArchiveEncryptionHeader(
      uuid: const Uuid().v4(),
      originalName: originalName,
      wasDirectory: wasDirectory,
      originalExtension: originalExtension,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }
}

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
  }) async {
    final inputEntity = FileSystemEntity.typeSync(inputPath);

    if (inputEntity == FileSystemEntityType.notFound) {
      throw EncryptionExceptionArchive('Input path not found: $inputPath');
    }

    final isDirectory = inputEntity == FileSystemEntityType.directory;
    final originalName = p.basename(inputPath);
    final originalExtension = isDirectory
        ? ''
        : p.extension(inputPath).replaceFirst('.', '');

    // Create temp file for compressed data
    final tempDir = await Directory.systemTemp.createTemp('enc_');
    final tempCompressedPath = p.join(tempDir.path, 'compressed.gz');

    try {
      int originalSize;
      int compressedSize;

      if (isDirectory) {
        // Directory: zip → gzip
        originalSize = await _getDirectorySize(Directory(inputPath));
        await _compressDirectory(inputPath, tempCompressedPath, onProgress);
      } else {
        // File: gzip only
        final file = File(inputPath);
        originalSize = await file.length();
        await _compressFile(inputPath, tempCompressedPath, onProgress);
      }

      compressedSize = await File(tempCompressedPath).length();

      // Create header
      final header = customUuid != null
          ? ArchiveEncryptionHeader(
              uuid: customUuid,
              originalName: originalName,
              wasDirectory: isDirectory,
              originalExtension: originalExtension,
              originalSize: originalSize,
              compressedSize: compressedSize,
            )
          : ArchiveEncryptionHeader.create(
              originalName: originalName,
              wasDirectory: isDirectory,
              originalExtension: originalExtension,
              originalSize: originalSize,
              compressedSize: compressedSize,
            );

      // Encrypt the compressed file with custom header
      final result = await _encryptWithArchiveHeader(
        inputPath: tempCompressedPath,
        outputPath: outputPath,
        password: password,
        header: header,
        onProgress: onProgress,
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
      await tempDir.delete(recursive: true);
    }
  }

  @override
  Future<DecryptionOperationResult> decrypt({
    required String inputPath,
    required String outputPath,
    required String password,
    ProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw DecryptionExceptionArchive('Input file not found: $inputPath');
    }

    // Create temp file for decrypted compressed data
    final tempDir = await Directory.systemTemp.createTemp('dec_');
    final tempCompressedPath = p.join(tempDir.path, 'compressed.gz');

    try {
      // Decrypt and get header
      final header = await _decryptWithArchiveHeader(
        inputPath: inputPath,
        outputPath: tempCompressedPath,
        password: password,
        onProgress: onProgress,
      );

      int bytesWritten;
      String finalOutputPath;

      if (header.wasDirectory) {
        // Decompress gzip → unzip
        finalOutputPath = p.join(outputPath, header.originalName);
        bytesWritten = await _decompressDirectory(
          tempCompressedPath,
          finalOutputPath,
          onProgress,
        );
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

        bytesWritten = await _decompressFile(
          tempCompressedPath,
          finalOutputPath,
          onProgress,
        );
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
      await tempDir.delete(recursive: true);
    }
  }

  @override
  Future<Uint8List> encryptBytes({
    required Uint8List data,
    required String password,
    String? customUuid,
  }) async {
    // Compress with gzip
    final compressed = GZipEncoder().encode(data);

    // Create header
    final header = ArchiveEncryptionHeader(
      uuid: customUuid ?? const Uuid().v4(),
      originalName: 'data',
      wasDirectory: false,
      originalExtension: '',
      originalSize: data.length,
      compressedSize: compressed.length,
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

    // Parse header (validates format, but we don't need metadata for decryptBytes)
    ArchiveEncryptionHeader.fromBytes(Uint8List.fromList(headerBytes));

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
    final decompressed = GZipDecoder().decodeBytes(compressedData);

    return Uint8List.fromList(decompressed);
  }

  /// Compresses a file with gzip using streaming.
  Future<void> _compressFile(
    String inputPath,
    String outputPath,
    ProgressCallback? onProgress,
  ) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    final totalSize = await inputFile.length();

    onProgress?.call(0, totalSize);

    // Use dart:io GZip for streaming compression
    final inputStream = inputFile.openRead();
    final outputSink = outputFile.openWrite();

    try {
      var chunksSinceFlush = 0;
      const flushInterval =
          16; // Flush every 16 chunks to prevent memory buildup

      // Transform stream through gzip encoder using await for
      await for (final chunk in inputStream.transform(gzip.encoder)) {
        outputSink.add(chunk);
        chunksSinceFlush++;

        // Periodic flush to prevent memory buildup
        if (chunksSinceFlush >= flushInterval) {
          await outputSink.flush();
          chunksSinceFlush = 0;
        }
      }

      await outputSink.flush();
      onProgress?.call(totalSize, totalSize);
    } finally {
      await outputSink.close();
    }
  }

  /// Compresses a directory to zip then gzip using streaming.
  Future<void> _compressDirectory(
    String inputPath,
    String outputPath,
    ProgressCallback? onProgress,
  ) async {
    final dir = Directory(inputPath);

    // Create temp file for zip
    final tempZipPath = '$outputPath.zip.tmp';
    final tempZipFile = File(tempZipPath);

    try {
      // Collect all files
      final files = await dir
          .list(recursive: true)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      var processed = 0;
      final total = files.length;

      // Create archive with streaming file reads
      final archive = Archive();

      for (final file in files) {
        final relativePath = p.relative(file.path, from: inputPath);
        // Read file content
        final data = await file.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, data.length, data));

        processed++;
        onProgress?.call(processed, total * 2); // First half: collecting files
      }

      // Write zip to temp file using stream
      final zipOutputStream = OutputFileStream(tempZipPath);
      ZipEncoder().encodeStream(archive, zipOutputStream);
      await zipOutputStream.close();

      // Now compress zip with gzip using streaming
      final zipInputStream = tempZipFile.openRead();
      final gzipOutputSink = File(outputPath).openWrite();

      try {
        await zipInputStream.transform(gzip.encoder).forEach((chunk) {
          gzipOutputSink.add(chunk);
        });

        await gzipOutputSink.flush();
        onProgress?.call(total * 2, total * 2); // Second half: gzip compression
      } finally {
        await gzipOutputSink.close();
      }
    } finally {
      // Clean up temp zip file
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
    }
  }

  /// Decompresses a gzip file using streaming.
  Future<int> _decompressFile(
    String inputPath,
    String outputPath,
    ProgressCallback? onProgress,
  ) async {
    final inputFile = File(inputPath);
    final inputSize = await inputFile.length();
    onProgress?.call(0, inputSize);

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);

    final inputStream = inputFile.openRead();
    final outputSink = outputFile.openWrite();

    var bytesWritten = 0;
    var chunksSinceFlush = 0;
    const flushInterval = 16;

    try {
      // Transform stream through gzip decoder using await for
      await for (final chunk in inputStream.transform(gzip.decoder)) {
        outputSink.add(chunk);
        bytesWritten += chunk.length;
        chunksSinceFlush++;

        if (chunksSinceFlush >= flushInterval) {
          await outputSink.flush();
          chunksSinceFlush = 0;
        }
      }

      await outputSink.flush();
      onProgress?.call(inputSize, inputSize);
    } finally {
      await outputSink.close();
    }

    return bytesWritten;
  }

  /// Decompresses gzip then extracts zip to directory using streaming.
  Future<int> _decompressDirectory(
    String inputPath,
    String outputPath,
    ProgressCallback? onProgress,
  ) async {
    final inputFile = File(inputPath);
    final inputSize = await inputFile.length();
    onProgress?.call(0, inputSize);

    // Create temp file for decompressed zip
    final tempZipPath = '$inputPath.zip.tmp';
    final tempZipFile = File(tempZipPath);

    try {
      // First decompress gzip to temp zip file using streaming
      final gzipInputStream = inputFile.openRead();
      final zipOutputSink = tempZipFile.openWrite();

      try {
        var chunksSinceFlush = 0;
        const flushInterval = 16;

        // Use await for instead of forEach for proper async handling
        await for (final chunk in gzipInputStream.transform(gzip.decoder)) {
          zipOutputSink.add(chunk);
          chunksSinceFlush++;

          if (chunksSinceFlush >= flushInterval) {
            await zipOutputSink.flush();
            chunksSinceFlush = 0;
          }
        }
        await zipOutputSink.flush();
      } finally {
        await zipOutputSink.close();
      }

      // Now extract zip using InputFileStream for memory efficiency
      final zipInputStream = InputFileStream(tempZipPath);
      final archive = ZipDecoder().decodeStream(zipInputStream);

      var bytesWritten = 0;
      final outputDir = Directory(outputPath);
      await outputDir.create(recursive: true);

      for (final file in archive) {
        final filePath = p.join(outputPath, file.name);

        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);

          // Get file content
          final content = file.readBytes();
          if (content != null) {
            await outFile.writeAsBytes(content);
            bytesWritten += content.length;
          }
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      await zipInputStream.close();
      onProgress?.call(inputSize, inputSize);
      return bytesWritten;
    } finally {
      // Clean up temp zip file
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
    }
  }

  /// Gets total size of a directory.
  Future<int> _getDirectorySize(Directory dir) async {
    var size = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Encrypts compressed file with archive header using streaming.
  ///
  /// Processes file in chunks to avoid loading entire file into memory.
  /// Uses streaming HMAC for incremental calculation.
  Future<int> _encryptWithArchiveHeader({
    required String inputPath,
    required String outputPath,
    required String password,
    required ArchiveEncryptionHeader header,
    ProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    final fileSize = await inputFile.length();

    // Derive key pair
    final keyPair = await KeyDerivationService.deriveKeyPair(
      password: password,
    );
    final cipher = Xchacha20.poly1305Aead();

    // Open files for streaming
    final inputStream = inputFile.openRead();
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    try {
      // Create streaming HMAC (no memory accumulation)
      final hmacSink = await _StreamingHmacArchive.create(keyPair.hmacKey);

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
      ByteData.view(chunkSizeBytes.buffer).setUint32(0, _chunkSize, Endian.big);
      outputSink.add(chunkSizeBytes);
      hmacSink.add(chunkSizeBytes);

      // Chunk count
      final chunkCount = fileSize == 0 ? 0 : ((fileSize - 1) ~/ _chunkSize) + 1;
      final chunkCountBytes = Uint8List(8);
      ByteData.view(chunkCountBytes.buffer).setInt64(0, chunkCount, Endian.big);
      outputSink.add(chunkCountBytes);
      hmacSink.add(chunkCountBytes);

      // Process file in chunks
      final buffer = _ChunkBufferArchive(_chunkSize);
      var bytesProcessed = 0;
      var chunksSinceFlush = 0;
      const flushInterval =
          8; // Flush every 8 chunks (~8MB) to prevent memory buildup

      await for (final data in inputStream) {
        buffer.addAll(data);

        while (buffer.hasFullChunk) {
          final chunkData = buffer.takeChunk();

          await _writeEncryptedChunk(
            chunkData: chunkData,
            encryptionKey: keyPair.encryptionKey,
            cipher: cipher,
            outputSink: outputSink,
            hmacSink: hmacSink,
          );

          bytesProcessed += chunkData.length;
          onProgress?.call(bytesProcessed, fileSize);

          // Clear sensitive data
          _clearBytes(chunkData);

          // Periodic flush to prevent memory buildup in IOSink
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
      await outputSink.close();

      return await outputFile.length();
    } catch (e) {
      await outputSink.close();
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      rethrow;
    }
  }

  /// Encrypts a single chunk and writes to output.
  Future<void> _writeEncryptedChunk({
    required Uint8List chunkData,
    required SecretKey encryptionKey,
    required StreamingCipher cipher,
    required IOSink outputSink,
    required _StreamingHmacArchive hmacSink,
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
  Future<ArchiveEncryptionHeader> _decryptWithArchiveHeader({
    required String inputPath,
    required String outputPath,
    required String password,
    ProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    final handle = await inputFile.open();

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
      final keyPair = await KeyDerivationService.deriveKeyPairWithSalt(
        password: password,
        salt: salt,
      );

      // Create streaming HMAC for verification
      final hmacSink = await _StreamingHmacArchive.create(keyPair.hmacKey);

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
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      final outputSink = outputFile.openWrite();

      try {
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
              ? (header.compressedSize - (chunkCount - 1) * chunkSize)
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
            throw AuthenticationExceptionArchive(
              'Chunk $i decryption failed - data may be corrupted',
            );
          }

          // Write decrypted chunk to output
          outputSink.add(decryptedChunk);
          bytesWritten += decryptedChunk.length;

          onProgress?.call(bytesWritten, header.compressedSize);
        }

        await outputSink.flush();
        await outputSink.close();

        // Verify final HMAC
        final storedHmac = await _readExactBytes(handle, 32);
        final calculatedMac = await hmacSink.finalize();

        if (!_constantTimeEquals(
          Uint8List.fromList(calculatedMac.bytes),
          storedHmac,
        )) {
          // Delete output file on HMAC failure
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
          throw const AuthenticationExceptionArchive(
            'HMAC verification failed',
          );
        }

        await handle.close();
        return header;
      } catch (e) {
        await outputSink.close();
        // Clean up partial output on error
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
        rethrow;
      }
    } catch (e) {
      await handle.close();
      rethrow;
    }
  }

  /// Reads exact number of bytes from file handle.
  Future<Uint8List> _readExactBytes(RandomAccessFile handle, int length) async {
    final bytes = await handle.read(length);
    if (bytes.length != length) {
      throw DecryptionExceptionArchive(
        'Unexpected end of file: expected $length bytes, got ${bytes.length}',
      );
    }
    return bytes;
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Best-effort clearing of sensitive bytes.
  void _clearBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}

/// Efficient buffer for collecting chunk data without excessive copying.
///
/// Uses a fixed-size buffer with write pointer for O(1) operations.
class _ChunkBufferArchive {
  final int _chunkSize;
  late Uint8List _buffer;
  int _writePos = 0;

  _ChunkBufferArchive(this._chunkSize) {
    // Allocate slightly larger buffer to handle incoming data efficiently
    _buffer = Uint8List(_chunkSize * 2);
  }

  /// Returns true if buffer contains at least one full chunk.
  bool get hasFullChunk => _writePos >= _chunkSize;

  /// Returns true if buffer has any data.
  bool get isNotEmpty => _writePos > 0;

  /// Adds data to the buffer.
  void addAll(List<int> data) {
    // Ensure capacity
    if (_writePos + data.length > _buffer.length) {
      final newBuffer = Uint8List((_writePos + data.length) * 2);
      newBuffer.setRange(0, _writePos, _buffer);
      _buffer = newBuffer;
    }
    _buffer.setRange(_writePos, _writePos + data.length, data);
    _writePos += data.length;
  }

  /// Takes one full chunk from the buffer.
  Uint8List takeChunk() {
    if (_writePos < _chunkSize) {
      throw StateError('Not enough data for a full chunk');
    }

    final chunk = Uint8List(_chunkSize);
    chunk.setRange(0, _chunkSize, _buffer);

    // Shift remaining data to start
    final remaining = _writePos - _chunkSize;
    if (remaining > 0) {
      _buffer.setRange(0, remaining, _buffer, _chunkSize);
    }
    _writePos = remaining;

    return chunk;
  }

  /// Takes all remaining data from the buffer.
  Uint8List takeRemaining() {
    final data = Uint8List(_writePos);
    data.setRange(0, _writePos, _buffer);
    _writePos = 0;
    return data;
  }
}

/// Streaming HMAC calculator using MacSink.
///
/// Computes HMAC incrementally without storing all data in memory.
/// Uses the cryptography package's MacSink for true streaming.
class _StreamingHmacArchive {
  final MacSink _sink;
  bool _closed = false;

  _StreamingHmacArchive._(this._sink);

  /// Creates a new streaming HMAC calculator with the given key.
  static Future<_StreamingHmacArchive> create(SecretKey hmacKey) async {
    final hmac = Hmac.sha256();
    final sink = await hmac.newMacSink(secretKey: hmacKey);
    return _StreamingHmacArchive._(sink);
  }

  /// Adds data to the HMAC calculation incrementally.
  void add(List<int> data) {
    if (_closed) {
      throw StateError('Cannot add data to closed HMAC sink');
    }
    _sink.add(data);
  }

  /// Finalizes and returns the HMAC.
  Future<Mac> finalize() async {
    if (_closed) {
      throw StateError('HMAC sink already closed');
    }
    _closed = true;
    _sink.close();
    return _sink.mac();
  }

  /// Clears state (sink handles cleanup automatically on close).
  void clear() {
    // MacSink handles cleanup when closed
    if (!_closed) {
      _sink.close();
      _closed = true;
    }
  }
}
