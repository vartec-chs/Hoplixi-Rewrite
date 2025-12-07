import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_crypto/file_crypto.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileStorageService {
  final MainStore _db;
  final ArchiveEncryptor _encryptor;
  final String _attachmentsPath;

  FileStorageService(this._db, this._attachmentsPath)
    : _encryptor = ArchiveEncryptor();

  /// Получить ключ шифрования из метаданных хранилища
  Future<String> _getAttachmentKey() async {
    final meta = await _db.select(_db.storeMetaTable).getSingle();
    return meta.attachmentKey;
  }

  /// Получить путь к директории вложений
  Future<String> _getAttachmentsPath() async {
    final directory = Directory(_attachmentsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _attachmentsPath;
  }

  /// Импортировать файл: шифрует и сохраняет в БД
  Future<String> importFile({
    required File sourceFile,
    required String name,
    String? description,
    String? categoryId,
    required List<String> tagsIds,
    void Function(int, int)? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final fileUuid = const Uuid().v4();
    final extension = p.extension(sourceFile.path);
    final encryptedFileName = '$fileUuid.enc';
    final encryptedFilePath = p.join(attachmentsPath, encryptedFileName);

    // Шифруем файл
    await _encryptor.encrypt(
      inputPath: sourceFile.path,
      outputPath: encryptedFilePath,
      password: key,
      onProgress: onProgress,
    );

    // Вычисляем хеш оригинального файла
    final digest = await sha256.bind(sourceFile.openRead()).first;
    final fileHash = digest.toString();

    final fileSize = await sourceFile.length();
    final fileName = p.basename(sourceFile.path);

    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

    final dto = CreateFileDto(
      name: name,
      fileName: fileName,
      fileExtension: extension,
      mimeType: mimeType,
      fileSize: fileSize,
      fileHash: fileHash,
      description: description,
      categoryId: categoryId,
      tagsIds: tagsIds,
    );

    return _db.fileDao.createFile(dto);
  }

  /// Расшифровать файл в указанный путь
  Future<void> decryptFile({
    required String fileId,
    required String destinationPath,
    void Function(int, int)? onProgress,
  }) async {
    final fileData = await _db.fileDao.getFileById(fileId);
    if (fileData == null) {
      throw Exception('File not found in database');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, fileData.filePath);

    if (!await File(encryptedFilePath).exists()) {
      throw Exception('Encrypted file not found on disk');
    }

    // Создаем временную директорию для расшифровки, так как ArchiveEncryptor
    // восстанавливает оригинальное имя файла, а нам нужно сохранить в destinationPath
    final tempDir = await Directory.systemTemp.createTemp('hoplixi_decrypt_');
    try {
      final result = await _encryptor.decrypt(
        inputPath: encryptedFilePath,
        outputPath: tempDir.path,
        password: key,
        onProgress: onProgress,
      );

      final decryptedFile = File(result.outputPath);
      if (await decryptedFile.exists()) {
        // Копируем файл в целевой путь
        // Убедимся, что директория назначения существует
        final destParent = Directory(p.dirname(destinationPath));
        if (!await destParent.exists()) {
          await destParent.create(recursive: true);
        }
        await decryptedFile.copy(destinationPath);
      } else {
        throw Exception(
          'Decryption finished but file not found at ${result.outputPath}',
        );
      }
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Удалить файл с диска (используется при удалении из БД)
  Future<void> deleteFileFromDisk(String fileId) async {
    final fileData = await _db.fileDao.getFileById(fileId);
    if (fileData == null) return;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, fileData.filePath);
    final file = File(encryptedFilePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
