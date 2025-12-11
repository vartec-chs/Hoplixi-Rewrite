/// Обертки для работы с SharedPreferences и FlutterSecureStorage
///
/// Этот пакет предоставляет типизированные ключи и унифицированный сервис
/// для работы с настройками приложения и защищённым хранилищем.
///
/// Используйте [AppKey] с флагом `isProtected` для определения типа хранилища:
/// - `isProtected: false` → SharedPreferences (по умолчанию)
/// - `isProtected: true` → FlutterSecureStorage
library;

// Категории настроек
export 'pref_category.dart';

// Унифицированный типизированный ключ
export 'app_key.dart';

// Унифицированный сервис хранения
export 'app_storage_service.dart';

// Ключи настроек приложения
export 'app_preference_keys.dart';

// UI-ориентированные ключи с метаданными
export 'settings_key.dart';
