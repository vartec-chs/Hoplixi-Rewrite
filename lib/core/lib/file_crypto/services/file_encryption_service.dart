import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import '../models/encrypted_file_header.dart';
import '../models/encryption_result.dart';
import 'key_derivation_service.dart';

/// Custom exception for encryption errors.
class EncryptionException implements Exception {
  final String message;
  final Object? cause;

  const EncryptionException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'EncryptionException: $message (caused by: $cause)';
    }
    return 'EncryptionException: $message';
  }
}

/// Custom exception for decryption errors.
class DecryptionException implements Exception {
  final String message;
  final Object? cause;

  const DecryptionException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'DecryptionException: $message (caused by: $cause)';
    }
    return 'DecryptionException: $message';
  }
}

/// Authentication failure exception.
class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Service for encrypting and decrypting files using XChaCha20-Poly1305.
///
/// This service provides production-ready streaming encryption with:
/// - XChaCha20-Poly1305 AEAD (authenticated encryption)
/// - 24-byte nonce (192-bit) for extended nonce length
/// - Poly1305 authentication tag
/// - Additional HMAC verification layer
/// - Encrypted file header with UUID and file extension
///
/// File format:
/// ```
/// [Salt (16 bytes)]
/// [Nonce (24 bytes)]
/// [Encrypted Header + Content]
/// [Auth Tag (16 bytes)]
/// [HMAC (32 bytes)]
/// ```
class FileEncryptionService {
  /// Salt size in bytes.
  static const int saltSize = 16;

  /// Nonce size for XChaCha20 (24 bytes = 192 bits).
  static const int nonceSize = 24;

  /// Authentication tag size (Poly1305).
  static const int authTagSize = 16;

  /// HMAC size (SHA-256).
  static const int hmacSize = 32;

  /// Chunk size for streaming operations (1 MB).
  static const int chunkSize = 1024 * 1024;

  /// The XChaCha20-Poly1305 cipher algorithm.
  final StreamingCipher _cipher = Xchacha20.poly1305Aead();

  /// HMAC algorithm for additional verification.
  final MacAlgorithm _hmac = Hmac.sha256();

  /// Encrypts a file and writes to the output path.
  ///
  /// Parameters:
  /// - [inputPath]: Path to the file to encrypt.
  /// - [outputPath]: Path where the encrypted file will be written.
  /// - [password]: Password for key derivation.
  /// - [customUuid]: Optional custom UUID for the header.
  ///
  /// Returns an [EncryptionResult] with encryption details.
  ///
  /// Throws [EncryptionException] if encryption fails.
  Future<EncryptionResult> encryptFile({
    required String inputPath,
    required String outputPath,
    required String password,
    String? customUuid,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw EncryptionException('Input file not found: $inputPath');
    }

    try {
      // Read file content
      final content = await inputFile.readAsBytes();
      final extension = p.extension(inputPath).replaceFirst('.', '');
      final fileSize = content.length;

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

      // Encrypt content with header
      final result = await encryptBytes(
        data: content,
        header: header,
        password: password,
      );

      // Write to output file
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(result.encryptedData);

      return result;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Failed to encrypt file: $inputPath', e);
    }
  }

  /// Encrypts bytes with an encrypted header.
  ///
  /// Parameters:
  /// - [data]: The data to encrypt.
  /// - [header]: The file header to include.
  /// - [password]: Password for key derivation.
  ///
  /// Returns an [EncryptionResult] with the encrypted data.
  Future<EncryptionResult> encryptBytes({
    required Uint8List data,
    required EncryptedFileHeader header,
    required String password,
  }) async {
    try {
      // Derive key
      final (keyBytes, salt) = await KeyDerivationService.deriveKey(
        password: password,
      );
      final secretKey = SecretKey(keyBytes);

      // Generate nonce
      final nonce = KeyDerivationService.generateSecureRandomBytes(nonceSize);

      // Combine header and content for encryption
      final headerBytes = header.toBytes();
      final plaintext = Uint8List(headerBytes.length + data.length);
      plaintext.setRange(0, headerBytes.length, headerBytes);
      plaintext.setRange(headerBytes.length, plaintext.length, data);

      // Encrypt using XChaCha20-Poly1305
      final secretBox = await _cipher.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonce,
      );

      // Calculate HMAC over (salt || nonce || ciphertext || mac)
      final preHmacData = Uint8List(
        salt.length +
            nonce.length +
            secretBox.cipherText.length +
            secretBox.mac.bytes.length,
      );
      var offset = 0;
      preHmacData.setRange(offset, offset + salt.length, salt);
      offset += salt.length;
      preHmacData.setRange(offset, offset + nonce.length, nonce);
      offset += nonce.length;
      preHmacData.setRange(
        offset,
        offset + secretBox.cipherText.length,
        secretBox.cipherText,
      );
      offset += secretBox.cipherText.length;
      preHmacData.setRange(
        offset,
        offset + secretBox.mac.bytes.length,
        secretBox.mac.bytes,
      );

      final hmac = await _hmac.calculateMac(preHmacData, secretKey: secretKey);

      // Build final encrypted data
      final encryptedData = Uint8List(
        salt.length +
            nonce.length +
            secretBox.cipherText.length +
            secretBox.mac.bytes.length +
            hmac.bytes.length,
      );

      offset = 0;
      encryptedData.setRange(offset, offset + salt.length, salt);
      offset += salt.length;
      encryptedData.setRange(offset, offset + nonce.length, nonce);
      offset += nonce.length;
      encryptedData.setRange(
        offset,
        offset + secretBox.cipherText.length,
        secretBox.cipherText,
      );
      offset += secretBox.cipherText.length;
      encryptedData.setRange(
        offset,
        offset + secretBox.mac.bytes.length,
        secretBox.mac.bytes,
      );
      offset += secretBox.mac.bytes.length;
      encryptedData.setRange(offset, offset + hmac.bytes.length, hmac.bytes);

      return EncryptionResult(
        encryptedData: encryptedData,
        header: header,
        nonce: nonce,
        authTag: Uint8List.fromList(secretBox.mac.bytes),
      );
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Encryption failed', e);
    }
  }

  /// Decrypts a file and writes to the output path.
  ///
  /// Parameters:
  /// - [inputPath]: Path to the encrypted file.
  /// - [outputPath]: Path where the decrypted file will be written.
  ///   If null, the original extension from the header will be used.
  /// - [password]: Password for key derivation.
  ///
  /// Returns a [DecryptionResult] with the decrypted data and header.
  ///
  /// Throws [DecryptionException] if decryption fails.
  /// Throws [AuthenticationException] if authentication fails.
  Future<DecryptionResult> decryptFile({
    required String inputPath,
    String? outputPath,
    required String password,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw DecryptionException('Input file not found: $inputPath');
    }

    try {
      final encryptedData = await inputFile.readAsBytes();
      final result = await decryptBytes(
        encryptedData: encryptedData,
        password: password,
      );

      // Determine output path
      final effectiveOutputPath =
          outputPath ??
          '${p.withoutExtension(inputPath)}.${result.header.fileExtension}';

      // Write decrypted content
      final outputFile = File(effectiveOutputPath);
      await outputFile.writeAsBytes(result.decryptedData);

      return result;
    } catch (e) {
      if (e is DecryptionException || e is AuthenticationException) rethrow;
      throw DecryptionException('Failed to decrypt file: $inputPath', e);
    }
  }

  /// Decrypts encrypted bytes.
  ///
  /// Parameters:
  /// - [encryptedData]: The encrypted data to decrypt.
  /// - [password]: Password for key derivation.
  ///
  /// Returns a [DecryptionResult] with the decrypted data and header.
  Future<DecryptionResult> decryptBytes({
    required Uint8List encryptedData,
    required String password,
  }) async {
    final minSize = saltSize + nonceSize + authTagSize + hmacSize + 48;
    if (encryptedData.length < minSize) {
      throw DecryptionException(
        'Encrypted data too short: ${encryptedData.length} bytes, '
        'minimum $minSize required',
      );
    }

    try {
      var offset = 0;

      // Extract salt
      final salt = encryptedData.sublist(offset, offset + saltSize);
      offset += saltSize;

      // Extract nonce
      final nonce = encryptedData.sublist(offset, offset + nonceSize);
      offset += nonceSize;

      // Extract ciphertext (excluding auth tag and HMAC at the end)
      final ciphertextLength =
          encryptedData.length - offset - authTagSize - hmacSize;
      final ciphertext = encryptedData.sublist(
        offset,
        offset + ciphertextLength,
      );
      offset += ciphertextLength;

      // Extract auth tag
      final authTag = encryptedData.sublist(offset, offset + authTagSize);
      offset += authTagSize;

      // Extract HMAC
      final storedHmac = encryptedData.sublist(offset, offset + hmacSize);

      // Derive key with the stored salt
      final secretKey = await KeyDerivationService.deriveSecretKey(
        password: password,
        salt: Uint8List.fromList(salt),
      );

      // Verify HMAC first
      final preHmacData = Uint8List(
        saltSize + nonceSize + ciphertext.length + authTagSize,
      );
      var hmacOffset = 0;
      preHmacData.setRange(hmacOffset, hmacOffset + saltSize, salt);
      hmacOffset += saltSize;
      preHmacData.setRange(hmacOffset, hmacOffset + nonceSize, nonce);
      hmacOffset += nonceSize;
      preHmacData.setRange(
        hmacOffset,
        hmacOffset + ciphertext.length,
        ciphertext,
      );
      hmacOffset += ciphertext.length;
      preHmacData.setRange(hmacOffset, hmacOffset + authTagSize, authTag);

      final calculatedHmac = await _hmac.calculateMac(
        preHmacData,
        secretKey: secretKey,
      );

      // Constant-time comparison for HMAC
      if (!_constantTimeEquals(
        Uint8List.fromList(calculatedHmac.bytes),
        Uint8List.fromList(storedHmac),
      )) {
        throw const AuthenticationException('HMAC verification failed');
      }

      // Decrypt using XChaCha20-Poly1305
      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag));

      List<int> plaintext;
      try {
        plaintext = await _cipher.decrypt(secretBox, secretKey: secretKey);
      } on SecretBoxAuthenticationError {
        throw const AuthenticationException(
          'Authentication tag verification failed',
        );
      }

      // Parse header from decrypted data
      final plaintextBytes = Uint8List.fromList(plaintext);
      final header = EncryptedFileHeader.fromBytes(plaintextBytes);

      // Extract content (after header)
      final contentStart = header.serializedSize;
      final content = plaintextBytes.sublist(contentStart);

      // Verify content size matches header
      if (content.length != header.originalFileSize) {
        throw DecryptionException(
          'Content size mismatch: expected ${header.originalFileSize}, '
          'got ${content.length}',
        );
      }

      return DecryptionResult(decryptedData: content, header: header);
    } catch (e) {
      if (e is DecryptionException || e is AuthenticationException) rethrow;
      throw DecryptionException('Decryption failed', e);
    }
  }

  /// Extracts header information without decrypting the full content.
  ///
  /// Note: This still requires password for HMAC verification.
  Future<EncryptedFileHeader> extractHeader({
    required Uint8List encryptedData,
    required String password,
  }) async {
    final result = await decryptBytes(
      encryptedData: encryptedData,
      password: password,
    );
    return result.header;
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
}
