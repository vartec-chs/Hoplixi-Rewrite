import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

/// Менеджер для управления хранилищами MainStore
///
/// Отвечает за создание, открытие, закрытие и управление
/// зашифрованными хранилищами паролей на основе Drift + SQLCipher
class MainStoreManager {
  static const String _logTag = 'MainStoreManager';
  static const String _dbExtension = MainConstants.dbExtension;
  static const String _attachmentsFolder = 'attachments';

  final DatabaseHistoryService _dbHistoryService;
  final _uuid = const Uuid();

  MainStore? _currentStore;
  String? _currentStorePath;
  String? _currentStoreId;

  MainStoreManager(this._dbHistoryService);

  /// Проверка, открыто ли хранилище
  bool get isStoreOpen => _currentStore != null && _currentStorePath != null;

  /// Получить текущий путь к хранилищу
  String? get currentStorePath => _currentStorePath;

  /// Создать новое хранилище
  ///
  /// [dto] - данные для создания хранилища
  /// Возвращает информацию о созданном хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> createStore(
    CreateStoreDto dto,
  ) async {
    try {
      logInfo('Creating new store: ${dto.name}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        return Failure(
          DatabaseError.alreadyInitialized(
            message: 'Хранилище уже открыто. Закройте текущее перед созданием нового.',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Нормализация имени папки
      final normalizedName = _normalizeStorageName(dto.name);
      final storagePath = await AppPaths.appStoragePath;
      final storageDir = Directory(p.join(storagePath, normalizedName));

      // Проверка существования папки
      if (await storageDir.exists()) {
        return Failure(
          DatabaseError.validationError(
            message: 'Хранилище с таким именем уже существует',
            data: {'path': storageDir.path},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Создание папки хранилища
      await storageDir.create(recursive: true);
      logInfo('Created storage directory: ${storageDir.path}', tag: _logTag);

      // Создание подпапки attachments
      final attachmentsDir = Directory(p.join(storageDir.path, _attachmentsFolder));
      await attachmentsDir.create(recursive: true);
      logInfo('Created attachments directory', tag: _logTag);

      // Генерация соли и хеширование пароля
      final salt = _uuid.v4();
      final passwordHash = _hashPassword(dto.password, salt);

      // Генерация ключа для вложений (для будущего использования)
      final attachmentKey = _uuid.v4();

      // Путь к файлу БД
      final dbFilePath = _getDbFilePath(storageDir.path, normalizedName);

      // Создание соединения с БД
      final dbResult = await _createDatabaseConnection(
        dbFilePath,
        dto.password,
      );

      if (dbResult.isError()) {
        // Удаляем созданную папку при ошибке
        await storageDir.delete(recursive: true);
        return Failure(dbResult.exceptionOrNull()!);
      }

      final database = dbResult.getOrThrow();
      _currentStore = database;
      _currentStorePath = storageDir.path;

      // Создание записи метаданных в БД
      final storeId = _uuid.v4();
      await database.into(database.storeMetaTable).insert(
            StoreMetaTableCompanion.insert(
              id: Value(storeId),
              name: dto.name,
              description: Value(dto.description),
              passwordHash: passwordHash,
              salt: salt,
              attachmentKey: attachmentKey,
              version: const Value('1.0.0'),
            ),
          );

      _currentStoreId = storeId;
      logInfo('Created store metadata with id: $storeId', tag: _logTag);

      // Добавление в историю
      await _dbHistoryService.create(
        path: storageDir.path,
        dbId: storeId,
        name: dto.name,
        description: dto.description,
        password: dto.saveMasterPassword ? dto.password : null,
        savePassword: dto.saveMasterPassword,
      );

      logInfo('Store created successfully: ${dto.name}', tag: _logTag);

      // Получение информации о созданном хранилище
      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to create store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось создать хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Открыть существующее хранилище
  ///
  /// [dto] - данные для открытия хранилища
  /// Возвращает информацию о хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> openStore(OpenStoreDto dto) async {
    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        return Failure(
          DatabaseError.alreadyInitialized(
            message: 'Хранилище уже открыто. Закройте текущее перед открытием нового.',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Проверка существования директории
      final storageDir = Directory(dto.path);
      if (!await storageDir.exists()) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Директория хранилища не найдена',
            data: {'path': dto.path},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Поиск файла БД
      final dbFilePath = await _findDatabaseFile(dto.path);
      if (dbFilePath == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Файл базы данных не найден в директории',
            data: {'path': dto.path},
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Found database file: $dbFilePath', tag: _logTag);

      // Создание соединения с БД
      final dbResult = await _createDatabaseConnection(
        dbFilePath,
        dto.password,
      );

      if (dbResult.isError()) {
        return Failure(dbResult.exceptionOrNull()!);
      }

      final database = dbResult.getOrThrow();

      // Проверка пароля и получение метаданных
      final verifyResult = await _verifyPassword(database, dto.password);
      if (verifyResult.isError()) {
        await database.close();
        return Failure(verifyResult.exceptionOrNull()!);
      }

      final storeMeta = verifyResult.getOrThrow();

      _currentStore = database;
      _currentStorePath = dto.path;
      _currentStoreId = storeMeta.id;

      // Обновление времени последнего доступа
      await database.update(database.storeMetaTable).replace(
            storeMeta.copyWith(lastOpenedAt: DateTime.now()),
          );

      // Обновление в истории
      await _dbHistoryService.updateLastAccessed(dto.path);

      logInfo('Store opened successfully', tag: _logTag);

      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to open store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось открыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Закрыть текущее хранилище
  AsyncResultDart<Unit, DatabaseError> closeStore() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Closing store', tag: _logTag);

      await _currentStore?.close();
      _currentStore = null;
      _currentStorePath = null;
      _currentStoreId = null;

      logInfo('Store closed successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to close store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось закрыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить информацию о текущем хранилище
  AsyncResultDart<StoreInfoDto, DatabaseError> getStoreInfo() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final query = _currentStore!.select(_currentStore!.storeMetaTable);
      final meta = await query.getSingleOrNull();

      if (meta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      final dto = StoreInfoDto(
        id: meta.id,
        name: meta.name,
        description: meta.description,
        createdAt: meta.createdAt,
        modifiedAt: meta.modifiedAt,
        lastOpenedAt: meta.lastOpenedAt,
        version: meta.version,
      );

      return Success(dto);
    } catch (e, stackTrace) {
      logError(
        'Failed to get store info: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.queryFailed(
          message: 'Не удалось получить информацию о хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Обновить метаданные хранилища
  AsyncResultDart<StoreInfoDto, DatabaseError> updateStore(
    UpdateStoreDto dto,
  ) async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Updating store metadata', tag: _logTag);

      final query = _currentStore!.select(_currentStore!.storeMetaTable);
      final currentMeta = await query.getSingleOrNull();

      if (currentMeta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Подготовка обновлений
      var updatedMeta = currentMeta.copyWith(modifiedAt: DateTime.now());

      if (dto.name != null) {
        updatedMeta = updatedMeta.copyWith(name: dto.name);
      }

      if (dto.description != null) {
        updatedMeta = updatedMeta.copyWith(description: Value(dto.description));
      }

      // Обновление пароля, если указано
      if (dto.password != null) {
        final newSalt = _uuid.v4();
        final newPasswordHash = _hashPassword(dto.password!, newSalt);
        updatedMeta = updatedMeta.copyWith(
          passwordHash: newPasswordHash,
          salt: newSalt,
        );
        logInfo('Password updated for store', tag: _logTag);
      }

      // Сохранение изменений
      await _currentStore!.update(_currentStore!.storeMetaTable).replace(updatedMeta);

      // Обновление в истории
      if (_currentStorePath != null) {
        final historyEntry = await _dbHistoryService.getByPath(_currentStorePath!);
        if (historyEntry != null) {
          await _dbHistoryService.update(
            historyEntry.copyWith(
              name: dto.name ?? historyEntry.name,
              description: dto.description != null ? Value(dto.description) : Value(historyEntry.description),
              password: dto.saveMasterPassword == true && dto.password != null
                  ? Value(dto.password)
                  : dto.saveMasterPassword == false
                      ? const Value(null)
                      : Value(historyEntry.password),
              savePassword: dto.saveMasterPassword ?? historyEntry.savePassword,
            ),
          );
        }
      }

      logInfo('Store metadata updated successfully', tag: _logTag);

      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to update store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.updateFailed(
          message: 'Не удалось обновить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить хранилище
  ///
  /// [path] - путь к директории хранилища
  /// [deleteFromDisk] - удалить файлы с диска (по умолчанию true)
  AsyncResultDart<Unit, DatabaseError> deleteStore(
    String path, {
    bool deleteFromDisk = true,
  }) async {
    try {
      logInfo('Deleting store at: $path', tag: _logTag);

      // Закрыть, если это текущее хранилище
      if (_currentStorePath == path && isStoreOpen) {
        await closeStore();
      }

      // Удаление из истории
      await _dbHistoryService.deleteByPath(path);

      // Удаление с диска
      if (deleteFromDisk) {
        final storageDir = Directory(path);
        if (await storageDir.exists()) {
          await storageDir.delete(recursive: true);
          logInfo('Store deleted from disk', tag: _logTag);
        }
      }

      logInfo('Store deleted successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.deleteFailed(
          message: 'Не удалось удалить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Создать подпапку в текущем хранилище
  ///
  /// [folderName] - имя подпапки
  /// Возвращает полный путь к созданной папке
  AsyncResult<String, DatabaseError> createSubfolder(String folderName) async {
    try {
      if (!isStoreOpen || _currentStorePath == null) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final normalizedName = _normalizeStorageName(folderName);
      final subfolderPath = p.join(_currentStorePath!, normalizedName);
      final subfolder = Directory(subfolderPath);

      if (await subfolder.exists()) {
        return Failure(
          DatabaseError.validationError(
            message: 'Папка с таким именем уже существует',
            data: {'path': subfolderPath},
            timestamp: DateTime.now(),
          ),
        );
      }

      await subfolder.create(recursive: true);
      logInfo('Created subfolder: $normalizedName', tag: _logTag);

      return Success(subfolderPath);
    } catch (e, stackTrace) {
      logError(
        'Failed to create subfolder: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось создать подпапку: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить путь к папке вложений
  AsyncResult<String, DatabaseError> getAttachmentsPath() async {
    try {
      if (!isStoreOpen || _currentStorePath == null) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final attachmentsPath = p.join(_currentStorePath!, _attachmentsFolder);
      return Success(attachmentsPath);
    } catch (e) {
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось получить путь к вложениям: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // === Приватные методы ===

  /// Нормализовать имя папки хранилища
  String _normalizeStorageName(String name) {
    // Удаляем лишние пробелы по краям
    var normalized = name.trim();

    // Заменяем пробелы на подчеркивания
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');

    // Удаляем недопустимые символы для файловой системы
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    // Если имя пустое после нормализации, используем UUID
    if (normalized.isEmpty) {
      normalized = _uuid.v4();
    }

    return normalized;
  }

  /// Получить путь к файлу БД
  String _getDbFilePath(String storagePath, String storageName) {
    return p.join(storagePath, '$storageName$_dbExtension');
  }

  /// Найти файл БД в директории
  Future<String?> _findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(_dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      logError('Failed to find database file: $e', tag: _logTag);
      return null;
    }
  }

  /// Создать соединение с БД с шифрованием
  AsyncResult<MainStore, DatabaseError> _createDatabaseConnection(
    String dbFilePath,
    String password,
  ) async {
    try {
      logInfo('Creating database connection', tag: _logTag);

      final executor = NativeDatabase.createInBackground(
        File(dbFilePath),
        setup: (rawDb) {
          // Установка ключа шифрования SQLCipher
          rawDb.execute("PRAGMA key = '$password'");
          // Дополнительные настройки SQLCipher
          rawDb.execute('PRAGMA cipher_page_size = 4096');
          rawDb.execute('PRAGMA kdf_iter = 256000');
          rawDb.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA512');
          rawDb.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512');
        },
      );

      final database = MainStore(executor);

      // Проверка соединения (попытка выполнить простой запрос)
      try {
        await database.customSelect('SELECT 1').getSingle();
        logInfo('Database connection established', tag: _logTag);
      } catch (e) {
        await database.close();
        logError('Failed to verify database connection: $e', tag: _logTag);
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль или поврежденная база данных',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(database);
    } catch (e, stackTrace) {
      logError(
        'Failed to create database connection: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось подключиться к базе данных: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Проверить пароль и получить метаданные
  AsyncResult<StoreMeta, DatabaseError> _verifyPassword(
    MainStore database,
    String password,
  ) async {
    try {
      final query = database.select(database.storeMetaTable);
      final meta = await query.getSingleOrNull();

      if (meta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Проверка хеша пароля
      final expectedHash = _hashPassword(password, meta.salt);
      if (expectedHash != meta.passwordHash) {
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(meta);
    } catch (e, stackTrace) {
      logError(
        'Failed to verify password: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.queryFailed(
          message: 'Не удалось проверить пароль: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Хешировать пароль с солью
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }
}
