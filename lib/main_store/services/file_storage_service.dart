import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/lib/file_crypto/file_crypto.dart';
import 'package:hoplixi/core/lib/file_crypto/interfaces/encryptor.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileStorageService {
  final MainStore _db;
  final ArchiveEncryptor _encryptor;

  FileStorageService(this._db) : _encryptor = ArchiveEncryptor();

  /// Получить ключ шифрования из метаданных хранилища
  Future<String> _getAttachmentKey() async {
    final meta = await _db.select(_db.storeMetaTable).getSingle();
    return meta.attachmentKey;
  }

  /// Получить путь к директории вложений
  Future<String> _getAttachmentsPath() async {
    final storagePath = await AppPaths.appStoragePath;
    final attachmentsPath = p.join(storagePath, 'attachments');
    final directory = Directory(attachmentsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return attachmentsPath;
  }

  /// Импортировать файл: шифрует и сохраняет в БД
  Future<String> importFile({
    required File sourceFile,
    required String name,
    String? description,
    String? categoryId,
    required List<String> tagsIds,
    ProgressCallback? onProgress,
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
    final fileBytes = await sourceFile.readAsBytes();
    final digest = sha256.convert(fileBytes);
    final fileHash = digest.toString();

    final fileSize = await sourceFile.length();
    final fileName = p.basename(sourceFile.path);

    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

    final dto = CreateFileDto(
      name: name,
      fileName: fileName,
      fileExtension: extension,
      filePath: encryptedFileName, // Сохраняем только имя файла
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
    ProgressCallback? onProgress,
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

    await _encryptor.decrypt(
      inputPath: encryptedFilePath,
      outputPath: destinationPath,
      password: key,
      onProgress: onProgress,
    );
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
