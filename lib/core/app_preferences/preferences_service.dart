import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pref_key.dart';
import 'pref_category.dart';

/// Сервис для работы с SharedPreferences с типизированными ключами
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Инициализация сервиса
  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // ==================== Получение значений ====================

  /// Получить значение по типизированному ключу
  T? get<T>(PrefKey<T> key) {
    if (T == String) {
      return _prefs.getString(key.key) as T?;
    } else if (T == int) {
      return _prefs.getInt(key.key) as T?;
    } else if (T == double) {
      return _prefs.getDouble(key.key) as T?;
    } else if (T == bool) {
      return _prefs.getBool(key.key) as T?;
    } else if (T == List<String>) {
      return _prefs.getStringList(key.key) as T?;
    }
    throw UnsupportedError('Type $T is not supported');
  }

  /// Получить значение или значение по умолчанию
  T getOrDefault<T>(PrefKey<T> key, T defaultValue) {
    return get(key) ?? defaultValue;
  }

  /// Получить строку
  String? getString(PrefKey<String> key) => _prefs.getString(key.key);

  /// Получить целое число
  int? getInt(PrefKey<int> key) => _prefs.getInt(key.key);

  /// Получить число с плавающей точкой
  double? getDouble(PrefKey<double> key) => _prefs.getDouble(key.key);

  /// Получить булево значение
  bool? getBool(PrefKey<bool> key) => _prefs.getBool(key.key);

  /// Получить список строк
  List<String>? getStringList(PrefKey<List<String>> key) =>
      _prefs.getStringList(key.key);

  /// Получить JSON объект
  Map<String, dynamic>? getJson(PrefKey<Map<String, dynamic>> key) {
    final jsonString = _prefs.getString(key.key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== Установка значений ====================

  /// Установить значение по типизированному ключу
  Future<bool> set<T>(PrefKey<T> key, T value) async {
    if (T == String) {
      return await _prefs.setString(key.key, value as String);
    } else if (T == int) {
      return await _prefs.setInt(key.key, value as int);
    } else if (T == double) {
      return await _prefs.setDouble(key.key, value as double);
    } else if (T == bool) {
      return await _prefs.setBool(key.key, value as bool);
    } else if (T == List<String>) {
      return await _prefs.setStringList(key.key, value as List<String>);
    }
    throw UnsupportedError('Type $T is not supported');
  }

  /// Установить строку
  Future<bool> setString(PrefKey<String> key, String value) =>
      _prefs.setString(key.key, value);

  /// Установить целое число
  Future<bool> setInt(PrefKey<int> key, int value) =>
      _prefs.setInt(key.key, value);

  /// Установить число с плавающей точкой
  Future<bool> setDouble(PrefKey<double> key, double value) =>
      _prefs.setDouble(key.key, value);

  /// Установить булево значение
  Future<bool> setBool(PrefKey<bool> key, bool value) =>
      _prefs.setBool(key.key, value);

  /// Установить список строк
  Future<bool> setStringList(PrefKey<List<String>> key, List<String> value) =>
      _prefs.setStringList(key.key, value);

  /// Установить JSON объект
  Future<bool> setJson(
    PrefKey<Map<String, dynamic>> key,
    Map<String, dynamic> value,
  ) {
    final jsonString = jsonEncode(value);
    return _prefs.setString(key.key, jsonString);
  }

  // ==================== Удаление и проверка ====================

  /// Удалить значение по ключу
  Future<bool> remove<T>(PrefKey<T> key) => _prefs.remove(key.key);

  /// Проверить наличие ключа
  bool containsKey<T>(PrefKey<T> key) => _prefs.containsKey(key.key);

  /// Очистить все настройки
  Future<bool> clear() => _prefs.clear();

  /// Получить все ключи
  Set<String> getKeys() => _prefs.getKeys();

  /// Перезагрузить настройки из хранилища
  Future<void> reload() => _prefs.reload();

  // ==================== Утилиты для UI ====================

  /// Получить все ключи по категории (для UI настроек)
  List<PrefKey> getKeysByCategory(
    PrefCategory category,
    List<PrefKey> allKeys,
  ) {
    return allKeys
        .where((key) => key.category == category && !key.isHiddenUI)
        .toList();
  }

  /// Получить все редактируемые ключи (для UI настроек)
  List<PrefKey> getEditableKeys(List<PrefKey> allKeys) {
    return allKeys.where((key) => key.editable && !key.isHiddenUI).toList();
  }

  /// Получить все видимые ключи (для UI настроек)
  List<PrefKey> getVisibleKeys(List<PrefKey> allKeys) {
    return allKeys.where((key) => !key.isHiddenUI).toList();
  }
}
