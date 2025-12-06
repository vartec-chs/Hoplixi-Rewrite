import 'dart:typed_data';

/// Progress callback for encryption/decryption operations.
typedef ProgressCallback = void Function(int bytesProcessed, int totalBytes);

/// Result of an encryption operation.
class EncryptionOperationResult {
  /// Unique identifier for the encrypted content.
  final String uuid;

  /// Path to the encrypted output file.
  final String outputPath;

  /// Original file or directory name.
  final String originalName;

  /// Whether the source was a directory.
  final bool wasDirectory;

  /// Original file extension (if file) or empty (if directory).
  final String originalExtension;

  /// Total bytes written to output.
  final int bytesWritten;

  /// Original size before compression and encryption.
  final int originalSize;

  const EncryptionOperationResult({
    required this.uuid,
    required this.outputPath,
    required this.originalName,
    required this.wasDirectory,
    required this.originalExtension,
    required this.bytesWritten,
    required this.originalSize,
  });

  @override
  String toString() =>
      'EncryptionOperationResult('
      'uuid: $uuid, '
      'originalName: $originalName, '
      'wasDirectory: $wasDirectory, '
      'bytesWritten: $bytesWritten)';
}

/// Result of a decryption operation.
class DecryptionOperationResult {
  /// Unique identifier from the encrypted content.
  final String uuid;

  /// Path to the decrypted output (file or directory).
  final String outputPath;

  /// Original file or directory name.
  final String originalName;

  /// Whether the content was a directory.
  final bool wasDirectory;

  /// Total bytes written to output.
  final int bytesWritten;

  const DecryptionOperationResult({
    required this.uuid,
    required this.outputPath,
    required this.originalName,
    required this.wasDirectory,
    required this.bytesWritten,
  });

  @override
  String toString() =>
      'DecryptionOperationResult('
      'uuid: $uuid, '
      'originalName: $originalName, '
      'wasDirectory: $wasDirectory, '
      'bytesWritten: $bytesWritten)';
}

/// Interface for file and directory encryption/decryption.
///
/// Implementations should handle:
/// - Single file encryption with gzip compression
/// - Directory encryption with zip + gzip compression
/// - Secure key derivation
/// - Authenticated encryption (AEAD)
abstract interface class IEncryptor {
  /// Encrypts a file or directory.
  ///
  /// For files:
  /// - Compresses with gzip
  /// - Encrypts with XChaCha20-Poly1305
  ///
  /// For directories:
  /// - Archives to zip
  /// - Compresses with gzip
  /// - Encrypts with XChaCha20-Poly1305
  ///
  /// Parameters:
  /// - [inputPath]: Path to the file or directory to encrypt.
  /// - [outputPath]: Path where the encrypted file will be written.
  /// - [password]: Password for key derivation.
  /// - [customUuid]: Optional custom UUID for tracking.
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns an [EncryptionOperationResult] with operation details.
  Future<EncryptionOperationResult> encrypt({
    required String inputPath,
    required String outputPath,
    required String password,
    String? customUuid,
    ProgressCallback? onProgress,
  });

  /// Decrypts an encrypted file.
  ///
  /// Automatically determines if the content was a file or directory
  /// and restores it accordingly.
  ///
  /// Parameters:
  /// - [inputPath]: Path to the encrypted file.
  /// - [outputPath]: Path where the decrypted content will be written.
  ///   For directories, this will be the parent directory.
  /// - [password]: Password for key derivation.
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns a [DecryptionOperationResult] with operation details.
  Future<DecryptionOperationResult> decrypt({
    required String inputPath,
    required String outputPath,
    required String password,
    ProgressCallback? onProgress,
  });

  /// Encrypts raw bytes.
  ///
  /// Parameters:
  /// - [data]: The data to encrypt.
  /// - [password]: Password for key derivation.
  /// - [customUuid]: Optional custom UUID.
  ///
  /// Returns encrypted bytes.
  Future<Uint8List> encryptBytes({
    required Uint8List data,
    required String password,
    String? customUuid,
  });

  /// Decrypts raw bytes.
  ///
  /// Parameters:
  /// - [encryptedData]: The encrypted data.
  /// - [password]: Password for key derivation.
  ///
  /// Returns decrypted bytes.
  Future<Uint8List> decryptBytes({
    required Uint8List encryptedData,
    required String password,
  });
}
