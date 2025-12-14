import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../interfaces/encryptor.dart';
import 'encryptor.dart';

/// Result of a batch operation on a single file.
class BatchFileResult {
  /// The original file path.
  final String originalPath;

  /// The output file path.
  final String outputPath;

  /// Whether the operation succeeded.
  final bool success;

  /// Error message if the operation failed.
  final String? error;

  /// The result if encryption/decryption succeeded.
  final EncryptionOperationResult? encryptionResult;
  final DecryptionOperationResult? decryptionResult;

  const BatchFileResult.success({
    required this.originalPath,
    required this.outputPath,
    this.encryptionResult,
    this.decryptionResult,
  }) : success = true,
       error = null;

  const BatchFileResult.failure({
    required this.originalPath,
    required this.error,
  }) : success = false,
       outputPath = '',
       encryptionResult = null,
       decryptionResult = null;

  @override
  String toString() {
    if (success) {
      return 'BatchFileResult.success(path: $originalPath -> $outputPath)';
    }
    return 'BatchFileResult.failure(path: $originalPath, error: $error)';
  }
}

/// Summary of a batch encryption/decryption operation.
class BatchOperationSummary {
  /// Results for each file processed.
  final List<BatchFileResult> results;

  /// Number of successfully processed files.
  int get successCount => results.where((r) => r.success).length;

  /// Number of failed files.
  int get failureCount => results.where((r) => !r.success).length;

  /// Total files processed.
  int get totalCount => results.length;

  /// Whether all files were processed successfully.
  bool get allSucceeded => failureCount == 0;

  /// Failed results only.
  List<BatchFileResult> get failures =>
      results.where((r) => !r.success).toList();

  /// Successful results only.
  List<BatchFileResult> get successes =>
      results.where((r) => r.success).toList();

  const BatchOperationSummary(this.results);

  @override
  String toString() {
    return 'BatchOperationSummary(success: $successCount, '
        'failed: $failureCount, total: $totalCount)';
  }
}

/// Progress callback for batch operations.
typedef BatchProgressCallback =
    void Function(int processedCount, int totalCount, String currentFile);

/// Service for encrypting and decrypting multiple files.
///
/// Provides batch operations with progress tracking and error handling.
/// Failed files don't stop the entire batch operation.
///
/// Uses [ArchiveEncryptor] to handle files efficiently.
class BatchEncryptionService {
  final ArchiveEncryptor _encryptionService;

  /// Creates a new batch encryption service.
  ///
  /// Optionally accepts a custom [ArchiveEncryptor] for testing.
  BatchEncryptionService([ArchiveEncryptor? encryptionService])
    : _encryptionService = encryptionService ?? ArchiveEncryptor();

  /// Encrypts multiple files.
  ///
  /// Parameters:
  /// - [inputPaths]: List of file paths to encrypt.
  /// - [outputDirectory]: Directory where encrypted files will be saved.
  /// - [password]: Password for encryption.
  /// - [outputExtension]: Extension for encrypted files (default: '.enc').
  /// - [onProgress]: Optional callback for progress updates.
  /// - [concurrency]: Number of files to process in parallel (default: 1).
  ///
  /// Returns a [BatchOperationSummary] with results for each file.
  Future<BatchOperationSummary> encryptFiles({
    required List<String> inputPaths,
    required String outputDirectory,
    required String password,
    String outputExtension = '.enc',
    BatchProgressCallback? onProgress,
    int concurrency = 1,
  }) async {
    if (inputPaths.isEmpty) {
      return const BatchOperationSummary([]);
    }

    // Ensure output directory exists
    final outputDir = Directory(outputDirectory);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final results = <BatchFileResult>[];
    var processedCount = 0;

    // Process files with concurrency control
    if (concurrency <= 1) {
      // Sequential processing
      for (final inputPath in inputPaths) {
        final result = await _encryptSingleFile(
          inputPath: inputPath,
          outputDirectory: outputDirectory,
          password: password,
          outputExtension: outputExtension,
        );
        results.add(result);
        processedCount++;
        onProgress?.call(processedCount, inputPaths.length, inputPath);
      }
    } else {
      // Parallel processing with limited concurrency
      final queue = List<String>.from(inputPaths);
      final futures = <Future<BatchFileResult>>[];

      while (queue.isNotEmpty || futures.isNotEmpty) {
        // Start new tasks up to concurrency limit
        while (futures.length < concurrency && queue.isNotEmpty) {
          final inputPath = queue.removeAt(0);
          futures.add(
            _encryptSingleFile(
              inputPath: inputPath,
              outputDirectory: outputDirectory,
              password: password,
              outputExtension: outputExtension,
            ),
          );
        }

        // Wait for any task to complete
        if (futures.isNotEmpty) {
          final completedFuture = await Future.any(
            futures.map((f) async {
              final result = await f;
              return (f, result);
            }),
          );
          futures.remove(completedFuture.$1);
          results.add(completedFuture.$2);
          processedCount++;
          onProgress?.call(
            processedCount,
            inputPaths.length,
            completedFuture.$2.originalPath,
          );
        }
      }
    }

    return BatchOperationSummary(results);
  }

  /// Decrypts multiple files.
  ///
  /// Parameters:
  /// - [inputPaths]: List of encrypted file paths to decrypt.
  /// - [outputDirectory]: Directory where decrypted files will be saved.
  /// - [password]: Password for decryption.
  /// - [onProgress]: Optional callback for progress updates.
  /// - [concurrency]: Number of files to process in parallel (default: 1).
  ///
  /// Returns a [BatchOperationSummary] with results for each file.
  Future<BatchOperationSummary> decryptFiles({
    required List<String> inputPaths,
    required String outputDirectory,
    required String password,
    BatchProgressCallback? onProgress,
    int concurrency = 1,
  }) async {
    if (inputPaths.isEmpty) {
      return const BatchOperationSummary([]);
    }

    // Ensure output directory exists
    final outputDir = Directory(outputDirectory);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final results = <BatchFileResult>[];
    var processedCount = 0;

    // Sequential processing for now (streaming operations are IO bound)
    // We could enable concurrency here too if needed.
    for (final inputPath in inputPaths) {
      final result = await _decryptSingleFile(
        inputPath: inputPath,
        outputDirectory: outputDirectory,
        password: password,
      );
      results.add(result);
      processedCount++;
      onProgress?.call(processedCount, inputPaths.length, inputPath);
    }

    return BatchOperationSummary(results);
  }

  /// Encrypts all files in a directory.
  ///
  /// Parameters:
  /// - [inputDirectory]: Directory containing files to encrypt.
  /// - [outputDirectory]: Directory where encrypted files will be saved.
  /// - [password]: Password for encryption.
  /// - [recursive]: Whether to include subdirectories (default: false).
  /// - [fileFilter]: Optional filter for file extensions (e.g., ['.pdf', '.doc']).
  /// - [outputExtension]: Extension for encrypted files (default: '.enc').
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns a [BatchOperationSummary] with results for each file.
  Future<BatchOperationSummary> encryptDirectory({
    required String inputDirectory,
    required String outputDirectory,
    required String password,
    bool recursive = false,
    List<String>? fileFilter,
    String outputExtension = '.enc',
    BatchProgressCallback? onProgress,
  }) async {
    final inputDir = Directory(inputDirectory);
    if (!await inputDir.exists()) {
      throw EncryptionExceptionArchive(
        'Input directory not found: $inputDirectory',
      );
    }

    final files = await _listFiles(
      directory: inputDir,
      recursive: recursive,
      fileFilter: fileFilter,
    );

    return encryptFiles(
      inputPaths: files,
      outputDirectory: outputDirectory,
      password: password,
      outputExtension: outputExtension,
      onProgress: onProgress,
    );
  }

  /// Decrypts all encrypted files in a directory.
  ///
  /// Parameters:
  /// - [inputDirectory]: Directory containing encrypted files.
  /// - [outputDirectory]: Directory where decrypted files will be saved.
  /// - [password]: Password for decryption.
  /// - [recursive]: Whether to include subdirectories (default: false).
  /// - [encryptedExtension]: Extension of encrypted files (default: '.enc').
  /// - [onProgress]: Optional callback for progress updates.
  ///
  /// Returns a [BatchOperationSummary] with results for each file.
  Future<BatchOperationSummary> decryptDirectory({
    required String inputDirectory,
    required String outputDirectory,
    required String password,
    bool recursive = false,
    String encryptedExtension = '.enc',
    BatchProgressCallback? onProgress,
  }) async {
    final inputDir = Directory(inputDirectory);
    if (!await inputDir.exists()) {
      throw DecryptionExceptionArchive(
        'Input directory not found: $inputDirectory',
      );
    }

    final files = await _listFiles(
      directory: inputDir,
      recursive: recursive,
      fileFilter: [encryptedExtension],
    );

    return decryptFiles(
      inputPaths: files,
      outputDirectory: outputDirectory,
      password: password,
      onProgress: onProgress,
    );
  }

  Future<BatchFileResult> _encryptSingleFile({
    required String inputPath,
    required String outputDirectory,
    required String password,
    required String outputExtension,
  }) async {
    try {
      final fileName = p.basename(inputPath);
      final outputPath = p.join(outputDirectory, '$fileName$outputExtension');

      final result = await _encryptionService.encrypt(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
      );

      return BatchFileResult.success(
        originalPath: inputPath,
        outputPath: outputPath,
        encryptionResult: result,
      );
    } catch (e) {
      return BatchFileResult.failure(
        originalPath: inputPath,
        error: e.toString(),
      );
    }
  }

  Future<BatchFileResult> _decryptSingleFile({
    required String inputPath,
    required String outputDirectory,
    required String password,
  }) async {
    try {
      // 1. Read header to determine output filename (from UUID + original extension)
      final header = await _encryptionService.readHeader(
        inputPath: inputPath,
        password: password,
      );

      // Build output path with UUID as filename and original extension
      final outputFileName = '${header.uuid}.${header.originalExtension}';
      final outputPath = p.join(outputDirectory, outputFileName);

      // 2. Decrypt to output path
      final result = await _encryptionService.decrypt(
        inputPath: inputPath,
        outputPath: outputPath,
        password: password,
      );

      return BatchFileResult.success(
        originalPath: inputPath,
        outputPath: outputPath,
        decryptionResult: result,
      );
    } catch (e) {
      return BatchFileResult.failure(
        originalPath: inputPath,
        error: e.toString(),
      );
    }
  }

  Future<List<String>> _listFiles({
    required Directory directory,
    required bool recursive,
    List<String>? fileFilter,
  }) async {
    final files = <String>[];

    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        final extension = p.extension(entity.path).toLowerCase();
        if (fileFilter == null || fileFilter.contains(extension)) {
          files.add(entity.path);
        }
      }
    }

    return files;
  }
}
