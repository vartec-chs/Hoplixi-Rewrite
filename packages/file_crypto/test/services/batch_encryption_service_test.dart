import 'dart:io';
import 'package:file_crypto/services/batch_encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BatchEncryptionService', () {
    late Directory tempDir;
    late BatchEncryptionService batchService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('batch_test_');
      batchService = BatchEncryptionService();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('encrypts multiple files successfully', () async {
      final file1 = File(p.join(tempDir.path, 'file1.txt'));
      final file2 = File(p.join(tempDir.path, 'file2.txt'));
      await file1.writeAsString('content1');
      await file2.writeAsString('content2');

      final outputDir = Directory(p.join(tempDir.path, 'encrypted'));
      await outputDir.create();

      final summary = await batchService.encryptFiles(
        inputPaths: [file1.path, file2.path],
        outputDirectory: outputDir.path,
        password: 'password',
      );

      expect(summary.allSucceeded, isTrue);
      expect(summary.successCount, equals(2));
      expect(summary.failureCount, equals(0));
      expect(
        File(p.join(outputDir.path, 'file1.txt.enc')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(outputDir.path, 'file2.txt.enc')).existsSync(),
        isTrue,
      );
    });

    test('handles failures gracefully', () async {
      final file1 = File(p.join(tempDir.path, 'file1.txt'));
      await file1.writeAsString('content1');
      final nonExistentPath = p.join(tempDir.path, 'non_existent.txt');

      final outputDir = Directory(p.join(tempDir.path, 'encrypted'));
      await outputDir.create();

      final summary = await batchService.encryptFiles(
        inputPaths: [file1.path, nonExistentPath],
        outputDirectory: outputDir.path,
        password: 'password',
      );

      expect(summary.allSucceeded, isFalse);
      expect(summary.successCount, equals(1));
      expect(summary.failureCount, equals(1));

      final failure = summary.failures.first;
      expect(failure.originalPath, equals(nonExistentPath));
      expect(failure.error, isNotNull);
    });

    test('decrypts multiple files successfully', () async {
      // Setup: Encrypt files first
      final file1 = File(p.join(tempDir.path, 'file1.txt'));
      final file2 = File(p.join(tempDir.path, 'file2.txt'));
      await file1.writeAsString('content1');
      await file2.writeAsString('content2');

      final encryptedDir = Directory(p.join(tempDir.path, 'encrypted'));
      await encryptedDir.create();

      await batchService.encryptFiles(
        inputPaths: [file1.path, file2.path],
        outputDirectory: encryptedDir.path,
        password: 'password',
      );

      final decryptedDir = Directory(p.join(tempDir.path, 'decrypted'));
      await decryptedDir.create();

      final encryptedFiles = encryptedDir
          .listSync()
          .map((e) => e.path)
          .toList();

      final summary = await batchService.decryptFiles(
        inputPaths: encryptedFiles,
        outputDirectory: decryptedDir.path,
        password: 'password',
      );

      expect(summary.allSucceeded, isTrue);
      expect(summary.successCount, equals(2));

      final decryptedFiles = decryptedDir
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      expect(decryptedFiles.length, equals(2));

      // Since filenames are UUIDs (directories) containing original files, we check content
      final contents = await Future.wait(
        decryptedFiles.map((f) => f.readAsString()),
      );
      expect(contents, containsAll(['content1', 'content2']));
    });

    test('reports progress', () async {
      final file1 = File(p.join(tempDir.path, 'file1.txt'));
      final file2 = File(p.join(tempDir.path, 'file2.txt'));
      await file1.writeAsString('content1');
      await file2.writeAsString('content2');

      final outputDir = Directory(p.join(tempDir.path, 'encrypted'));
      await outputDir.create();

      int progressCalls = 0;
      await batchService.encryptFiles(
        inputPaths: [file1.path, file2.path],
        outputDirectory: outputDir.path,
        password: 'password',
        onProgress: (processed, total, currentFile) {
          progressCalls++;
          expect(total, equals(2));
          expect(processed, lessThanOrEqualTo(total));
        },
      );

      expect(progressCalls, greaterThanOrEqualTo(2));
    });
  });
}
