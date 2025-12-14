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
