# File Crypto SDK Guide for AI Assistants

This document describes how to use the `file_crypto` package in Dart/Flutter projects. Use this context to generate correct code for file encryption and decryption tasks.

## Package Overview

`file_crypto` provides secure file and directory encryption using XChaCha20-Poly1305 with Argon2id key derivation. It handles compression (Gzip/Zip), chunking, and metadata management automatically.

## Core Classes

### 1. ArchiveEncryptor

The main class for single file/directory operations.

**Key Methods:**

- `encrypt({required String inputPath, required String outputPath, required String password, ...})`
- `decrypt({required String inputPath, required String outputPath, required String password, ...})`
- `readHeader({required String inputPath, required String password})`

### 2. BatchEncryptionService

For processing multiple files with progress tracking.

**Key Methods:**

- `encryptFiles({required List<String> inputPaths, required String outputDirectory, ...})`
- `decryptFiles({required List<String> inputPaths, required String outputDirectory, ...})`

### 3. KeyDerivationService

Utilities for key generation (mostly used internally, but useful for validation).

## Usage Patterns

### Pattern 1: Encrypt a Single File

```dart
import 'package:file_crypto/file_crypto.dart';

final encryptor = ArchiveEncryptor();
try {
  final result = await encryptor.encrypt(
    inputPath: 'path/to/file.pdf',
    outputPath: 'path/to/file.pdf.enc', // Full path to output file
    password: 'user_password',
    onProgress: (processed, total) {
      print('Progress: ${(processed / total * 100).toStringAsFixed(1)}%');
    },
  );
  print('Encrypted UUID: ${result.uuid}');
} on EncryptionExceptionArchive catch (e) {
  print('Encryption failed: ${e.message}');
}
```

### Pattern 2: Decrypt a File

**Important:** The `outputPath` parameter in `decrypt` must be a **directory**. The original filename and extension are restored automatically from the encrypted header.

```dart
final encryptor = ArchiveEncryptor();
try {
  final result = await encryptor.decrypt(
    inputPath: 'path/to/file.pdf.enc',
    outputPath: 'path/to/output_dir', // Directory where file will be restored
    password: 'user_password',
  );
  // result.outputPath contains the full path to the restored file
  print('Restored to: ${result.outputPath}'); 
} on AuthenticationExceptionArchive {
  print('Wrong password or corrupted file');
}
```

### Pattern 3: Encrypt a Directory

Directories are automatically zipped before encryption.

```dart
await encryptor.encrypt(
  inputPath: 'path/to/directory',
  outputPath: 'path/to/archive.enc',
  password: 'password',
);
```

### Pattern 4: Read Metadata (Header)

Read file info without full decryption.

```dart
final header = await encryptor.readHeader(
  inputPath: 'path/to/file.enc',
  password: 'password',
);
print('Original Name: ${header.originalName}');
print('Is Directory: ${header.wasDirectory}');
print('Compressed Size: ${header.compressedSize}');
```

### Pattern 5: Batch Processing

```dart
final batchService = BatchEncryptionService();
final summary = await batchService.encryptFiles(
  inputPaths: ['file1.txt', 'file2.png'],
  outputDirectory: 'encrypted_output/',
  password: 'password',
  concurrency: 3, // Parallel processing
  onProgress: (processed, total, currentFile) {
    print('Batch progress: $processed/$total ($currentFile)');
  },
);

if (!summary.allSucceeded) {
  print('Failed files: ${summary.failures.map((f) => f.originalPath)}');
}
```

## Error Handling

- `AuthenticationExceptionArchive`: Wrong password or HMAC verification failed.
- `EncryptionExceptionArchive`: Input file not found, permission denied, etc.
- `DecryptionExceptionArchive`: Corrupted data or format errors.

## Important Notes

- **Paths**: `decrypt`'s `outputPath` is a **directory**.
- **Isolates**: Large files (>100MB) are automatically processed in a separate Isolate to avoid UI jank.
- **Security**: Keys are derived using Argon2id. Do not hardcode passwords.
- **Extensions**: The default extension for encrypted files is usually `.enc`, but the library handles any extension.
