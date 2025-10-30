import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'secure_key.dart';
import 'pref_category.dart';

/// Сервис для работы с FlutterSecureStorage с типизированными ключами
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  /// Инициализация сервиса с настройками по умолчанию
  static SecureStorageService init({
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    LinuxOptions? linuxOptions,
    WindowsOptions? windowsOptions,
    MacOsOptions? macOsOptions,
    WebOptions? webOptions,
  }) {
    final storage = FlutterSecureStorage(
      aOptions: androidOptions ?? _defaultAndroidOptions(),
      iOptions: iosOptions ?? _defaultIOSOptions(),
      lOptions: linuxOptions ?? const LinuxOptions(),
      wOptions: windowsOptions ?? const WindowsOptions(),
      mOptions: macOsOptions ?? const MacOsOptions(),
      webOptions: webOptions ?? const WebOptions(),
    );
    return SecureStorageService(storage);
  }

  /// Настройки по умолчанию для Android
  static AndroidOptions _defaultAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  /// Настройки по умолчанию для iOS
  static IOSOptions _defaultIOSOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  // ==================== Получение значений ====================

  /// Получить значение по типизированному ключу
  Future<T?> get<T>(SecureKey<T> key) async {
    final value = await _storage.read(key: key.key);
    if (value == null) return null;

    if (T == String) {
      return value as T;
    } else if (T == int) {
      return int.tryParse(value) as T?;
    } else if (T == double) {
      return double.tryParse(value) as T?;
    } else if (T == bool) {
      return (value.toLowerCase() == 'true') as T;
    }
    throw UnsupportedError('Type $T is not supported');
  }

  /// Получить значение или значение по умолчанию
  Future<T> getOrDefault<T>(SecureKey<T> key, T defaultValue) async {
    final value = await get(key);
    return value ?? defaultValue;
  }

  /// Получить строку
  Future<String?> getString(SecureKey<String> key) =>
      _storage.read(key: key.key);

  /// Получить целое число
  Future<int?> getInt(SecureKey<int> key) async {
    final value = await _storage.read(key: key.key);
    return value != null ? int.tryParse(value) : null;
  }

  /// Получить число с плавающей точкой
  Future<double?> getDouble(SecureKey<double> key) async {
    final value = await _storage.read(key: key.key);
    return value != null ? double.tryParse(value) : null;
  }

  /// Получить булево значение
  Future<bool?> getBool(SecureKey<bool> key) async {
    final value = await _storage.read(key: key.key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  /// Получить JSON объект
  Future<Map<String, dynamic>?> getJson(
    SecureKey<Map<String, dynamic>> key,
  ) async {
    final jsonString = await _storage.read(key: key.key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Получить список (сериализованный как JSON)
  Future<List<T>?> getList<T>(SecureKey<List<T>> key) async {
    final jsonString = await _storage.read(key: key.key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<T>();
    } catch (e) {
      return null;
    }
  }

  // ==================== Установка значений ====================

  /// Установить значение по типизированному ключу
  Future<void> set<T>(SecureKey<T> key, T value) async {
    String stringValue;
    if (value is String) {
      stringValue = value;
    } else if (value is int || value is double || value is bool) {
      stringValue = value.toString();
    } else {
      throw UnsupportedError('Type $T is not supported');
    }
    await _storage.write(key: key.key, value: stringValue);
  }

  /// Установить строку
  Future<void> setString(SecureKey<String> key, String value) =>
      _storage.write(key: key.key, value: value);

  /// Установить целое число
  Future<void> setInt(SecureKey<int> key, int value) =>
      _storage.write(key: key.key, value: value.toString());

  /// Установить число с плавающей точкой
  Future<void> setDouble(SecureKey<double> key, double value) =>
      _storage.write(key: key.key, value: value.toString());

  /// Установить булево значение
  Future<void> setBool(SecureKey<bool> key, bool value) =>
      _storage.write(key: key.key, value: value.toString());

  /// Установить JSON объект
  Future<void> setJson(
    SecureKey<Map<String, dynamic>> key,
    Map<String, dynamic> value,
  ) {
    final jsonString = jsonEncode(value);
    return _storage.write(key: key.key, value: jsonString);
  }

  /// Установить список (сериализуется как JSON)
  Future<void> setList<T>(SecureKey<List<T>> key, List<T> value) {
    final jsonString = jsonEncode(value);
    return _storage.write(key: key.key, value: jsonString);
  }

  // ==================== Удаление и проверка ====================

  /// Удалить значение по ключу
  Future<void> remove<T>(SecureKey<T> key) => _storage.delete(key: key.key);

  /// Проверить наличие ключа
  Future<bool> containsKey<T>(SecureKey<T> key) =>
      _storage.containsKey(key: key.key);

  /// Получить все ключи
  Future<Map<String, String>> getAll() => _storage.readAll();

  /// Очистить все значения
  Future<void> clear() => _storage.deleteAll();

  // ==================== Утилиты для UI ====================

  /// Получить все ключи по категории (для UI настроек)
  List<SecureKey> getKeysByCategory(
    PrefCategory category,
    List<SecureKey> allKeys,
  ) {
    return allKeys
        .where((key) => key.category == category && !key.isHiddenUI)
        .toList();
  }

  /// Получить все редактируемые ключи (для UI настроек)
  List<SecureKey> getEditableKeys(List<SecureKey> allKeys) {
    return allKeys.where((key) => key.editable && !key.isHiddenUI).toList();
  }

  /// Получить все видимые ключи (для UI настроек)
  List<SecureKey> getVisibleKeys(List<SecureKey> allKeys) {
    return allKeys.where((key) => !key.isHiddenUI).toList();
  }
}
