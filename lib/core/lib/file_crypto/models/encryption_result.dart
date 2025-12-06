import 'dart:typed_data';

import 'encrypted_file_header.dart';

/// Result of file encryption operation.
class EncryptionResult {
  /// The encrypted file data including header, nonce, ciphertext, and auth tag.
  final Uint8List encryptedData;

  /// The parsed header containing file metadata.
  final EncryptedFileHeader header;

  /// The nonce/IV used for encryption.
  final Uint8List nonce;

  /// The authentication tag (Poly1305 MAC).
  final Uint8List authTag;

  const EncryptionResult({
    required this.encryptedData,
    required this.header,
    required this.nonce,
    required this.authTag,
  });

  @override
  String toString() {
    return 'EncryptionResult(header: $header, '
        'nonceLength: ${nonce.length}, '
        'authTagLength: ${authTag.length}, '
        'dataLength: ${encryptedData.length})';
  }
}

/// Result of file decryption operation.
class DecryptionResult {
  /// The decrypted file data (original content).
  final Uint8List decryptedData;

  /// The parsed header containing file metadata.
  final EncryptedFileHeader header;

  const DecryptionResult({required this.decryptedData, required this.header});

  @override
  String toString() {
    return 'DecryptionResult(header: $header, '
        'dataLength: ${decryptedData.length})';
  }
}
