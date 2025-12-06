import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import '../models/encrypted_file_header.dart';
import 'file_encryption_service.dart';
import 'key_derivation_service.dart';

/// Progress callback for streaming operations.
typedef StreamProgressCallback =
    void Function(int bytesProcessed, int totalBytes);

/// Result of streaming encryption operation.
class StreamEncryptionResult {
  /// The file header containing metadata.
  final EncryptedFileHeader header;

  /// Path to the encrypted output file.
  final String outputPath;

  /// Total bytes written.
  final int bytesWritten;

  const StreamEncryptionResult({
    required this.header,
    required this.outputPath,
    required this.bytesWritten,
  });

  @override
  String toString() =>
      'StreamEncryptionResult(uuid: ${header.uuid}, bytes: $bytesWritten)';
}

/// Result of streaming decryption operation.
class StreamDecryptionResult {
  /// The file header containing metadata.
  final EncryptedFileHeader header;

  /// Path to the decrypted output file.
  final String outputPath;

  /// Total bytes written.
  final int bytesWritten;

  const StreamDecryptionResult({
    required this.header,
    required this.outputPath,
    required this.bytesWritten,
  });

  @override
  String toString() =>
      'StreamDecryptionResult(uuid: ${header.uuid}, bytes: $bytesWritten)';
}

/// Service for streaming encryption and decryption of large files.
///
/// This service processes files in chunks to avoid loading the entire file
/// into memory. It uses XChaCha20-Poly1305 with per-chunk authentication
/// and separate keys for AEAD and HMAC.
///
/// Streaming file format (version 1):
/// ```
/// [Magic "SENC" (4 bytes)]
/// [Version (1 byte)]
/// [Salt (16 bytes)]
/// [Header Nonce (24 bytes)]
/// [Header Length (4 bytes, uint32 big-endian)]
/// [Encrypted Header (variable)]
/// [Header Auth Tag (16 bytes)]
/// [Chunk Size (4 bytes, uint32 big-endian)]
/// [Chunk Count (8 bytes, uint64 big-endian)]
/// For each chunk:
///   [Chunk Nonce (24 bytes)]
///   [Encrypted Chunk Data]
///   [Chunk Auth Tag (16 bytes)]
/// [Final HMAC (32 bytes)]
/// ```
///
/// Security features:
/// - Magic bytes and version for format validation and future compatibility
/// - Separate keys derived via Argon2id: one for AEAD, one for HMAC
/// - Explicit header length prevents parsing ambiguity
/// - Per-chunk authentication for early tamper detection
/// - Final HMAC over entire file for integrity verification
class StreamingEncryptionService {
  /// Magic bytes identifying the file format.
  static const List<int> magic = [0x53, 0x45, 0x4E, 0x43]; // "SENC"

  /// Current file format version.
  static const int formatVersion = 1;

  /// Default chunk size (1 MB).
  static const int defaultChunkSize = 1024 * 1024;

  /// Minimum chunk size (64 KB).
  static const int minChunkSize = 64 * 1024;

  /// Maximum chunk size (16 MB).
  static const int maxChunkSize = 16 * 1024 * 1024;

  /// Salt size in bytes.
  static const int saltSize = 16;

  /// Nonce size for XChaCha20.
  static const int nonceSize = 24;

  /// Authentication tag size (Poly1305).
  static const int authTagSize = 16;

  /// HMAC size (SHA-256).
  static const int hmacSize = 32;

  /// Header length field size (4 bytes uint32).
  static const int headerLengthSize = 4;

  /// Chunk size field size (4 bytes uint32).
  static const int chunkSizeFieldSize = 4;

  /// Chunk count field size (8 bytes uint64).
  static const int chunkCountSize = 8;

  /// Fixed overhead at start of file before chunks.
  static int get fixedHeaderOverhead =>
      magic.length + // Magic "SENC"
      1 + // Version
      saltSize + // Salt
      nonceSize + // Header nonce
      headerLengthSize + // Header length
      authTagSize + // Header auth tag
      chunkSizeFieldSize + // Chunk size
      chunkCountSize; // Chunk count

  /// Chunk size for streaming operations.
  final int chunkSize;

  /// The XChaCha20-Poly1305 cipher algorithm.
  final StreamingCipher _cipher = Xchacha20.poly1305Aead();

  /// Creates a streaming encryption service.
  ///
  /// Parameters:
  /// - [chunkSize]: Size of each chunk in bytes (default: 1 MB).
  StreamingEncryptionService({this.chunkSize = defaultChunkSize}) {
    if (chunkSize < minChunkSize) {
      throw ArgumentError('Chunk size must be at least $minChunkSize bytes');
    }
    if (chunkSize > maxChunkSize) {
      throw ArgumentError('Chunk size must be at most $maxChunkSize bytes');
    }
  }

  /// Encrypts a file using streaming to minimize memory usage.
  ///
  /// The file is read and encrypted in chunks, each chunk is independently
  /// authenticated. Uses separate keys for AEAD and HMAC for security.
  ///
  /// Parameters:
  /// - [inputPath]: Path to the file to encrypt.
  /// - [outputPath]: Path where the encrypted file will be written.
  /// - [password]: Password for key derivation.
  /// - [customUuid]: Optional custom UUID for the header.
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns a [StreamEncryptionResult] with encryption details.
  Future<StreamEncryptionResult> encryptFile({
    required String inputPath,
    required String outputPath,
    required String password,
    String? customUuid,
    StreamProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw EncryptionException('Input file not found: $inputPath');
    }

    final fileSize = await inputFile.length();
    final extension = p.extension(inputPath).replaceFirst('.', '');

    // Create header
    final header = customUuid != null
        ? EncryptedFileHeader(
            uuid: customUuid,
            fileExtension: extension,
            originalFileSize: fileSize,
          )
        : EncryptedFileHeader.create(
            fileExtension: extension,
            originalFileSize: fileSize,
          );

    // Derive key pair (separate keys for AEAD and HMAC)
    final keyPair = await KeyDerivationService.deriveKeyPair(
      password: password,
    );

    // Open files
    final inputStream = inputFile.openRead();
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    try {
      var bytesProcessed = 0;

      // Use streaming HMAC for incremental calculation (no memory accumulation)
      final hmacSink = await _StreamingHmac.create(keyPair.hmacKey);

      // Write magic and version
      final magicAndVersion = Uint8List(magic.length + 1);
      magicAndVersion.setAll(0, magic);
      magicAndVersion[magic.length] = formatVersion;
      outputSink.add(magicAndVersion);
      hmacSink.add(magicAndVersion);

      // Write salt
      outputSink.add(keyPair.salt);
      hmacSink.add(keyPair.salt);

      // Encrypt header
      final headerBytes = header.toBytes();
      final headerNonce = KeyDerivationService.generateSecureRandomBytes(
        nonceSize,
      );
      final headerBox = await _cipher.encrypt(
        headerBytes,
        secretKey: keyPair.encryptionKey,
        nonce: headerNonce,
      );

      // Write header nonce
      outputSink.add(headerNonce);
      hmacSink.add(headerNonce);

      // Write header length (explicit, no guessing needed during decryption)
      final headerLengthBytes = Uint8List(headerLengthSize);
      final headerLengthView = ByteData.view(headerLengthBytes.buffer);
      headerLengthView.setUint32(0, headerBox.cipherText.length, Endian.big);
      outputSink.add(headerLengthBytes);
      hmacSink.add(headerLengthBytes);

      // Write encrypted header and auth tag
      final headerCiphertext = Uint8List.fromList(headerBox.cipherText);
      final headerAuthTag = Uint8List.fromList(headerBox.mac.bytes);
      outputSink.add(headerCiphertext);
      outputSink.add(headerAuthTag);
      hmacSink.add(headerCiphertext);
      hmacSink.add(headerAuthTag);

      // Write chunk size for decryption
      final chunkSizeBytes = Uint8List(chunkSizeFieldSize);
      final chunkSizeView = ByteData.view(chunkSizeBytes.buffer);
      chunkSizeView.setUint32(0, chunkSize, Endian.big);
      outputSink.add(chunkSizeBytes);
      hmacSink.add(chunkSizeBytes);

      // Calculate and write chunk count
      final chunkCount = fileSize == 0 ? 0 : ((fileSize - 1) ~/ chunkSize) + 1;
      final chunkCountBytes = Uint8List(chunkCountSize);
      final chunkCountView = ByteData.view(chunkCountBytes.buffer);
      chunkCountView.setInt64(0, chunkCount, Endian.big);
      outputSink.add(chunkCountBytes);
      hmacSink.add(chunkCountBytes);

      // Process file in chunks using efficient buffer
      final buffer = _ChunkBuffer(chunkSize);

      await for (final data in inputStream) {
        buffer.addAll(data);

        while (buffer.hasFullChunk) {
          final chunkData = buffer.takeChunk();

          await _writeEncryptedChunk(
            chunkData: chunkData,
            encryptionKey: keyPair.encryptionKey,
            outputSink: outputSink,
            hmacSink: hmacSink,
          );

          bytesProcessed += chunkData.length;
          onProgress?.call(bytesProcessed, fileSize);

          // Clear sensitive data
          _clearBytes(chunkData);
        }
      }

      // Process remaining data
      if (buffer.isNotEmpty) {
        final remainingData = buffer.takeRemaining();
        await _writeEncryptedChunk(
          chunkData: remainingData,
          encryptionKey: keyPair.encryptionKey,
          outputSink: outputSink,
          hmacSink: hmacSink,
        );
        bytesProcessed += remainingData.length;
        onProgress?.call(bytesProcessed, fileSize);

        // Clear sensitive data
        _clearBytes(remainingData);
      }

      // Finalize streaming HMAC (no memory accumulation!)
      final finalHmac = await hmacSink.finalize();
      outputSink.add(finalHmac.bytes);

      await outputSink.flush();
      await outputSink.close();

      // Clean up
      keyPair.destroy();

      final outputSize = await File(outputPath).length();

      return StreamEncryptionResult(
        header: header,
        outputPath: outputPath,
        bytesWritten: outputSize,
      );
    } catch (e) {
      await outputSink.close();
      keyPair.destroy();
      // Clean up partial output on error
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Streaming encryption failed', e);
    }
  }

  /// Decrypts a file using streaming to minimize memory usage.
  ///
  /// Each chunk is verified independently, allowing early failure detection
  /// if any chunk has been tampered with.
  ///
  /// Parameters:
  /// - [inputPath]: Path to the encrypted file.
  /// - [outputPath]: Path where the decrypted file will be written.
  ///   If null, uses the original extension from the header.
  /// - [password]: Password for key derivation.
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns a [StreamDecryptionResult] with decryption details.
  Future<StreamDecryptionResult> decryptFile({
    required String inputPath,
    String? outputPath,
    required String password,
    StreamProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw DecryptionException('Input file not found: $inputPath');
    }

    final inputHandle = await inputFile.open();
    DerivedKeyPair? keyPair;
    _StreamingHmac? hmacSink;

    try {
      // Read and verify magic
      final magicBytes = await _readBytes(inputHandle, magic.length);
      if (!_listEquals(magicBytes, magic)) {
        throw const DecryptionException(
          'Invalid file format: missing SENC magic bytes',
        );
      }

      // Read and verify version
      final versionBytes = await _readBytes(inputHandle, 1);
      final version = versionBytes[0];
      if (version != formatVersion) {
        throw DecryptionException(
          'Unsupported file format version: $version (expected $formatVersion)',
        );
      }

      // Read salt
      final salt = await _readBytes(inputHandle, saltSize);

      // Derive key pair
      keyPair = await KeyDerivationService.deriveKeyPairWithSalt(
        password: password,
        salt: salt,
      );

      // Create streaming HMAC now that we have the key
      hmacSink = await _StreamingHmac.create(keyPair.hmacKey);

      // Add already-read data to HMAC
      hmacSink.add(magicBytes);
      hmacSink.add(versionBytes);
      hmacSink.add(salt);

      // Read header nonce
      final headerNonce = await _readBytes(inputHandle, nonceSize);
      hmacSink.add(headerNonce);

      // Read header length (explicit, no guessing!)
      final headerLengthBytes = await _readBytes(inputHandle, headerLengthSize);
      hmacSink.add(headerLengthBytes);
      final headerLengthView = ByteData.view(headerLengthBytes.buffer);
      final headerLength = headerLengthView.getUint32(0, Endian.big);

      // Validate header length
      if (headerLength > 10000) {
        throw const DecryptionException(
          'Invalid header length: exceeds maximum allowed size',
        );
      }

      // Read encrypted header
      final headerCiphertext = await _readBytes(inputHandle, headerLength);
      hmacSink.add(headerCiphertext);

      // Read header auth tag
      final headerAuthTag = await _readBytes(inputHandle, authTagSize);
      hmacSink.add(headerAuthTag);

      // Decrypt header
      final headerBox = SecretBox(
        headerCiphertext,
        nonce: headerNonce,
        mac: Mac(headerAuthTag),
      );

      List<int> headerPlaintext;
      try {
        headerPlaintext = await _cipher.decrypt(
          headerBox,
          secretKey: keyPair.encryptionKey,
        );
      } on SecretBoxAuthenticationError {
        throw const AuthenticationException(
          'Failed to decrypt file header: authentication failed',
        );
      }

      final header = EncryptedFileHeader.fromBytes(
        Uint8List.fromList(headerPlaintext),
      );

      // Read chunk size
      final chunkSizeBytes = await _readBytes(inputHandle, chunkSizeFieldSize);
      hmacSink.add(chunkSizeBytes);
      final chunkSizeView = ByteData.view(chunkSizeBytes.buffer);
      final storedChunkSize = chunkSizeView.getUint32(0, Endian.big);

      // Read chunk count
      final chunkCountBytes = await _readBytes(inputHandle, chunkCountSize);
      hmacSink.add(chunkCountBytes);
      final chunkCountView = ByteData.view(chunkCountBytes.buffer);
      final chunkCount = chunkCountView.getInt64(0, Endian.big);

      // Determine output path
      final effectiveOutputPath =
          outputPath ??
          '${p.withoutExtension(inputPath)}.${header.fileExtension}';

      // Open output file
      final outputFile = File(effectiveOutputPath);
      final outputSink = outputFile.openWrite();

      try {
        var bytesWritten = 0;
        final expectedContentSize = header.originalFileSize;

        // Decrypt chunks
        for (var i = 0; i < chunkCount; i++) {
          // Read chunk nonce
          final chunkNonce = await _readBytes(inputHandle, nonceSize);
          hmacSink.add(chunkNonce);

          // Determine chunk data size
          int chunkDataSize;
          if (i < chunkCount - 1) {
            chunkDataSize = storedChunkSize;
          } else {
            // Last chunk - calculate remaining
            chunkDataSize = expectedContentSize - bytesWritten;
          }

          // Read encrypted chunk data + auth tag
          final chunkCiphertext = await _readBytes(inputHandle, chunkDataSize);
          final chunkAuthTag = await _readBytes(inputHandle, authTagSize);
          hmacSink.add(chunkCiphertext);
          hmacSink.add(chunkAuthTag);

          // Decrypt chunk
          final chunkBox = SecretBox(
            chunkCiphertext,
            nonce: chunkNonce,
            mac: Mac(chunkAuthTag),
          );

          List<int> plaintext;
          try {
            plaintext = await _cipher.decrypt(
              chunkBox,
              secretKey: keyPair.encryptionKey,
            );
          } on SecretBoxAuthenticationError {
            throw AuthenticationException(
              'Chunk $i authentication failed - file may be corrupted',
            );
          }

          outputSink.add(plaintext);
          bytesWritten += plaintext.length;
          onProgress?.call(bytesWritten, expectedContentSize);
        }

        // Verify final HMAC using streaming calculation (no memory accumulation!)
        final storedHmac = await _readBytes(inputHandle, hmacSize);
        final calculatedHmac = await hmacSink.finalize();

        if (!_constantTimeEquals(
          Uint8List.fromList(calculatedHmac.bytes),
          storedHmac,
        )) {
          throw const AuthenticationException(
            'Final HMAC verification failed - file may be corrupted',
          );
        }

        await outputSink.flush();
        await outputSink.close();
        await inputHandle.close();

        // Clean up
        keyPair.destroy();

        // Verify written size
        if (bytesWritten != expectedContentSize) {
          throw DecryptionException(
            'Size mismatch: expected $expectedContentSize, got $bytesWritten',
          );
        }

        return StreamDecryptionResult(
          header: header,
          outputPath: effectiveOutputPath,
          bytesWritten: bytesWritten,
        );
      } catch (e) {
        await outputSink.close();
        // Clean up partial output on error
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
        rethrow;
      }
    } catch (e) {
      await inputHandle.close();
      keyPair?.destroy();
      hmacSink?.clear();
      if (e is DecryptionException || e is AuthenticationException) rethrow;
      throw DecryptionException('Streaming decryption failed', e);
    }
  }

  /// Encrypts a single chunk and writes to output.
  Future<void> _writeEncryptedChunk({
    required Uint8List chunkData,
    required SecretKey encryptionKey,
    required IOSink outputSink,
    required _StreamingHmac hmacSink,
  }) async {
    // Generate unique nonce for this chunk
    final chunkNonce = KeyDerivationService.generateSecureRandomBytes(
      nonceSize,
    );

    // Encrypt chunk
    final chunkBox = await _cipher.encrypt(
      chunkData,
      secretKey: encryptionKey,
      nonce: chunkNonce,
    );

    // Write: nonce + ciphertext + auth tag
    final ciphertext = Uint8List.fromList(chunkBox.cipherText);
    final authTag = Uint8List.fromList(chunkBox.mac.bytes);

    outputSink.add(chunkNonce);
    outputSink.add(ciphertext);
    outputSink.add(authTag);

    // Add to streaming HMAC (no memory accumulation)
    hmacSink.add(chunkNonce);
    hmacSink.add(ciphertext);
    hmacSink.add(authTag);
  }

  /// Reads exact number of bytes from file handle.
  Future<Uint8List> _readBytes(RandomAccessFile handle, int length) async {
    final bytes = await handle.read(length);
    if (bytes.length != length) {
      throw DecryptionException(
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

  /// Compares two lists for equality.
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Best-effort clearing of sensitive bytes.
  void _clearBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  /// Estimates the encrypted file size for a given input size.
  ///
  /// Useful for progress reporting and disk space checks.
  int estimateEncryptedSize(int inputSize) {
    final chunkCount = inputSize == 0 ? 0 : ((inputSize - 1) ~/ chunkSize) + 1;
    final chunkOverhead = (nonceSize + authTagSize) * chunkCount;

    // Magic + version + salt + header nonce + header length + header (~100 bytes)
    // + header auth tag + chunk size + chunk count + chunks + final HMAC
    return magic.length +
        1 + // version
        saltSize +
        nonceSize +
        headerLengthSize +
        100 + // estimated header ciphertext
        authTagSize +
        chunkSizeFieldSize +
        chunkCountSize +
        inputSize +
        chunkOverhead +
        hmacSize;
  }
}

/// Efficient buffer for collecting chunk data without excessive copying.
///
/// Uses a fixed-size buffer with write pointer for O(1) operations.
class _ChunkBuffer {
  final int _chunkSize;
  late Uint8List _buffer;
  int _writePos = 0;

  _ChunkBuffer(this._chunkSize) {
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

/// Efficient collector for HMAC data.
/// Streaming HMAC calculator using MacSink.
///
/// Computes HMAC incrementally without storing all data in memory.
/// Uses the cryptography package's MacSink for true streaming.
class _StreamingHmac {
  final MacSink _sink;
  bool _closed = false;

  _StreamingHmac._(this._sink);

  /// Creates a new streaming HMAC calculator with the given key.
  static Future<_StreamingHmac> create(SecretKey hmacKey) async {
    final hmac = Hmac.sha256();
    final sink = await hmac.newMacSink(secretKey: hmacKey);
    return _StreamingHmac._(sink);
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
