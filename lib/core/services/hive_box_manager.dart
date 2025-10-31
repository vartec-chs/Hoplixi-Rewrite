import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce/src/box/default_compaction_strategy.dart';
import 'package:hive_ce/src/box/default_key_comparator.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Менеджер для управления Hive боксами с шифрованием
///
/// Автоматически генерирует и сохраняет ключи шифрования в FlutterSecureStorage.
/// Ключи хранятся в формате: "hive_box_key_{boxName}"
class HiveBoxManager {
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'hive_box_key_';
  static const String _logTag = 'HiveBoxManager';
  bool _initialized = false;

  HiveBoxManager(this._secureStorage);

  /// Инициализация Hive с путем к директории
  Future<void> initialize() async {
    if (_initialized) {
      logWarning('HiveBoxManager already initialized', tag: _logTag);
      return;
    }

    try {
      final boxPath = await AppPaths.boxDbPath;
      Hive.init(boxPath);
      _initialized = true;
      logInfo('HiveBoxManager initialized at: $boxPath', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize HiveBoxManager: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Проверка инициализации
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'HiveBoxManager is not initialized. Call initialize() first.',
      );
    }
  }

  /// Получить или создать ключ шифрования для бокса
  Future<List<int>> _getOrCreateEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';

    // Попытка получить существующий ключ
    final existingKey = await _secureStorage.read(key: keyName);
    if (existingKey != null) {
      try {
        final decoded = base64Decode(existingKey);
        logInfo(
          'Using existing encryption key for box: $boxName',
          tag: _logTag,
        );
        return decoded;
      } catch (e) {
        logWarning(
          'Failed to decode existing key for $boxName, generating new one',
          tag: _logTag,
        );
      }
    }

    // Генерация нового ключа
    final newKey = Hive.generateSecureKey();
    final encoded = base64Encode(newKey);
    await _secureStorage.write(key: keyName, value: encoded);
    logInfo('Generated new encryption key for box: $boxName', tag: _logTag);
    return newKey;
  }

  /// Получить ключ шифрования из secure storage
  Future<List<int>?> _getStoredEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    final existingKey = await _secureStorage.read(key: keyName);
    if (existingKey != null) {
      try {
        return base64Decode(existingKey);
      } catch (e) {
        logError(
          'Failed to decode encryption key for $boxName: $e',
          tag: _logTag,
        );
        return null;
      }
    }
    return null;
  }

  /// Сохранить пользовательский ключ шифрования
  Future<void> _saveEncryptionKey(String boxName, List<int> key) async {
    final keyName = '$_keyPrefix$boxName';
    final encoded = base64Encode(key);
    await _secureStorage.write(key: keyName, value: encoded);
    logInfo('Saved custom encryption key for box: $boxName', tag: _logTag);
  }

  /// Открыть или создать зашифрованный бокс
  ///
  /// [boxName] - имя бокса
  /// [encryptionKey] - пользовательский ключ шифрования (опционально)
  /// Если ключ не указан, будет сгенерирован и сохранен автоматически
  Future<Box<E>> openBox<E>(
    String boxName, {
    List<int>? encryptionKey,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
  }) async {
    _ensureInitialized();

    try {
      // Проверка, открыт ли уже бокс
      if (Hive.isBoxOpen(boxName)) {
        logInfo('Box $boxName is already open', tag: _logTag);
        return Hive.box<E>(boxName);
      }

      // Получение или создание ключа шифрования
      final List<int> key;
      if (encryptionKey != null) {
        key = encryptionKey;
        await _saveEncryptionKey(boxName, key);
      } else {
        key = await _getOrCreateEncryptionKey(boxName);
      }

      // Создание cipher для шифрования
      final encryptionCipher = HiveAesCipher(Uint8List.fromList(key));

      // Открытие бокса
      final box = await Hive.openBox<E>(
        boxName,
        encryptionCipher: encryptionCipher,
        keyComparator: keyComparator,
        compactionStrategy: compactionStrategy,
        crashRecovery: crashRecovery,
      );

      logInfo('Successfully opened box: $boxName', tag: _logTag);
      return box;
    } catch (e, stackTrace) {
      logError(
        'Failed to open box $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Открыть или создать ленивый зашифрованный бокс
  ///
  /// [boxName] - имя бокса
  /// [encryptionKey] - пользовательский ключ шифрования (опционально)
  Future<LazyBox<E>> openLazyBox<E>(
    String boxName, {
    List<int>? encryptionKey,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
  }) async {
    _ensureInitialized();

    try {
      // Проверка, открыт ли уже бокс
      if (Hive.isBoxOpen(boxName)) {
        logInfo('Lazy box $boxName is already open', tag: _logTag);
        return Hive.lazyBox<E>(boxName);
      }

      // Получение или создание ключа шифрования
      final List<int> key;
      if (encryptionKey != null) {
        key = encryptionKey;
        await _saveEncryptionKey(boxName, key);
      } else {
        key = await _getOrCreateEncryptionKey(boxName);
      }

      // Создание cipher для шифрования
      final encryptionCipher = HiveAesCipher(Uint8List.fromList(key));

      // Открытие ленивого бокса
      final box = await Hive.openLazyBox<E>(
        boxName,
        encryptionCipher: encryptionCipher,
        keyComparator: keyComparator,
        compactionStrategy: compactionStrategy,
        crashRecovery: crashRecovery,
      );

      logInfo('Successfully opened lazy box: $boxName', tag: _logTag);
      return box;
    } catch (e, stackTrace) {
      logError(
        'Failed to open lazy box $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Получить открытый бокс
  Box<E> getBox<E>(String boxName) {
    _ensureInitialized();
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call openBox() first.');
    }
    return Hive.box<E>(boxName);
  }

  /// Получить открытый ленивый бокс
  LazyBox<E> getLazyBox<E>(String boxName) {
    _ensureInitialized();
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError(
        'Lazy box $boxName is not open. Call openLazyBox() first.',
      );
    }
    return Hive.lazyBox<E>(boxName);
  }

  /// Проверить, открыт ли бокс
  bool isBoxOpen(String boxName) {
    _ensureInitialized();
    return Hive.isBoxOpen(boxName);
  }

  /// Проверить, существует ли бокс на диске
  Future<bool> boxExists(String boxName) async {
    _ensureInitialized();
    try {
      return await Hive.boxExists(boxName);
    } catch (e) {
      logError('Failed to check if box exists: $e', tag: _logTag);
      return false;
    }
  }

  /// Закрыть бокс
  Future<void> closeBox(String boxName) async {
    _ensureInitialized();
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.compact();
        await box.close();
        logInfo('Closed box: $boxName', tag: _logTag);
      } else {
        logWarning(
          'Attempted to close box that is not open: $boxName',
          tag: _logTag,
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to close box $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Удалить бокс с диска и его ключ шифрования
  Future<void> deleteBox(String boxName) async {
    _ensureInitialized();
    try {
      // Закрыть бокс, если он открыт
      if (Hive.isBoxOpen(boxName)) {
        await closeBox(boxName);
      }

      // Удалить бокс с диска
      await Hive.deleteBoxFromDisk(boxName);

      // Удалить ключ шифрования
      final keyName = '$_keyPrefix$boxName';
      await _secureStorage.delete(key: keyName);

      logInfo('Deleted box and encryption key: $boxName', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete box $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Закрыть все открытые боксы
  Future<void> closeAll() async {
    _ensureInitialized();
    try {
      await Hive.close();
      logInfo('Closed all boxes', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to close all boxes: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Удалить все боксы с диска и все ключи шифрования
  Future<void> deleteAllBoxes() async {
    _ensureInitialized();
    try {
      // Закрыть все боксы
      await closeAll();

      // Удалить все боксы с диска
      await Hive.deleteFromDisk();

      // Удалить все ключи шифрования
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }

      logInfo('Deleted all boxes and encryption keys', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete all boxes: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Компактировать бокс (оптимизация хранения)
  Future<void> compactBox(String boxName) async {
    _ensureInitialized();
    try {
      if (!Hive.isBoxOpen(boxName)) {
        throw StateError('Box $boxName is not open');
      }
      final box = Hive.box(boxName);
      await box.compact();
      logInfo('Compacted box: $boxName', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to compact box $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Получить список всех сохраненных ключей шифрования (названия боксов)
  Future<List<String>> getAllBoxNames() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final boxNames = allKeys.keys
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toList();
      return boxNames;
    } catch (e) {
      logError('Failed to get all box names: $e', tag: _logTag);
      return [];
    }
  }

  /// Экспортировать ключ шифрования бокса (для бэкапа)
  Future<String?> exportBoxKey(String boxName) async {
    try {
      final key = await _getStoredEncryptionKey(boxName);
      if (key == null) return null;
      return base64Encode(key);
    } catch (e) {
      logError('Failed to export box key for $boxName: $e', tag: _logTag);
      return null;
    }
  }

  /// Импортировать ключ шифрования бокса (для восстановления)
  Future<void> importBoxKey(String boxName, String encodedKey) async {
    try {
      final key = base64Decode(encodedKey);
      await _saveEncryptionKey(boxName, key);
      logInfo('Imported encryption key for box: $boxName', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to import box key for $boxName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }
}
