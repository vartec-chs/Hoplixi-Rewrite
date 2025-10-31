import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'preferences_service.dart';
import 'secure_storage_service.dart';
import 'app_preference_keys.dart';
import 'pref_category.dart';

/// Примеры использования PreferencesService и SecureStorageService

void exampleUsage() async {
  // ==================== Инициализация ====================

  // Инициализация SharedPreferences
  final prefsService = await PreferencesService.init();

  // Инициализация FlutterSecureStorage
  final secureStorage = SecureStorageService.init(
    FlutterSecureStorage(
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      lOptions: const LinuxOptions(),
      wOptions: const WindowsOptions(),
      mOptions: const MacOsOptions(),
      webOptions: const WebOptions(),
    ),
  );

  // ==================== Работа с SharedPreferences ====================

  // Сохранение значений
  await prefsService.set(AppPreferenceKeys.themeMode, 'dark');
  await prefsService.setInt(AppPreferenceKeys.autoLockTimeout, 300);
  await prefsService.setBool(AppPreferenceKeys.biometricEnabled, true);
  await prefsService.setDouble(AppPreferenceKeys.fontSize, 14.5);

  // Сохранение JSON
  await prefsService.setJson(AppPreferenceKeys.userSettings, {
    'theme': 'dark',
    'notifications': true,
    'language': 'ru',
  });

  // Сохранение списка
  await prefsService.setStringList(AppPreferenceKeys.recentSearches, [
    'password',
    'email',
    'login',
  ]);

  // Чтение значений
  final themeMode = prefsService.get(AppPreferenceKeys.themeMode);
  final timeout = prefsService.getInt(AppPreferenceKeys.autoLockTimeout);
  final biometric = prefsService.getBool(AppPreferenceKeys.biometricEnabled);
  final fontSize = prefsService.getDouble(AppPreferenceKeys.fontSize);

  // Чтение с значением по умолчанию
  final language = prefsService.getOrDefault(AppPreferenceKeys.language, 'en');

  // Чтение JSON
  final userSettings = prefsService.getJson(AppPreferenceKeys.userSettings);

  // Проверка наличия ключа
  if (prefsService.containsKey(AppPreferenceKeys.isFirstLaunch)) {
    debugPrint('Приложение уже запускалось');
  } else {
    await prefsService.setBool(AppPreferenceKeys.isFirstLaunch, false);
  }

  // Удаление значения
  await prefsService.remove(AppPreferenceKeys.recentSearches);

  // Получение всех ключей
  final allKeys = prefsService.getKeys();
  debugPrint('Всего ключей: ${allKeys.length}');

  // ==================== Работа с FlutterSecureStorage ====================

  // Сохранение конфиденциальных данных
  await secureStorage.setString(
    AppSecureKeys.masterPassword,
    'super_secret_password',
  );
  await secureStorage.setString(
    AppSecureKeys.encryptionKey,
    'encryption_key_base64',
  );
  await secureStorage.setInt(AppSecureKeys.pinAttempts, 0);

  // Сохранение JSON (как строка)
  await secureStorage.setString(
    AppSecureKeys.cloudCredentials,
    '{"username":"user@example.com","token":"secret_token"}',
  );

  // Сохранение JSON объекта
  await secureStorage.setJson(AppSecureKeys.userSessionData, {
    'userId': '12345',
    'sessionId': 'abc-def-ghi',
    'expiresAt': DateTime.now().millisecondsSinceEpoch,
  });

  // Чтение конфиденциальных данных
  final masterPassword = await secureStorage.getString(
    AppSecureKeys.masterPassword,
  );
  final encryptionKey = await secureStorage.getString(
    AppSecureKeys.encryptionKey,
  );
  final pinAttempts = await secureStorage.getInt(AppSecureKeys.pinAttempts);

  // Чтение с значением по умолчанию
  final attempts = await secureStorage.getOrDefault(
    AppSecureKeys.pinAttempts,
    0,
  );

  // Чтение JSON (как строка)
  final credentials = await secureStorage.getString(
    AppSecureKeys.cloudCredentials,
  );

  // Чтение JSON объекта
  final sessionData = await secureStorage.getJson(
    AppSecureKeys.userSessionData,
  );

  // Проверка наличия ключа
  final hasPassword = await secureStorage.containsKey(
    AppSecureKeys.masterPassword,
  );

  if (!hasPassword) {
    debugPrint('Мастер-пароль не установлен');
  }

  // Удаление значения
  await secureStorage.remove(AppSecureKeys.accessToken);

  // Получение всех ключей
  final allSecureData = await secureStorage.getAll();
  debugPrint('Всего защищенных ключей: ${allSecureData.length}');

  // Очистка всех данных (осторожно!)
  // await secureStorage.clear();

  // ==================== Работа с UI настройками ====================

  // Получить все видимые настройки
  final visibleKeys = prefsService.getVisibleKeys(
    AppPreferenceKeys.getAllKeys(),
  );

  // Получить редактируемые настройки
  final editableKeys = prefsService.getEditableKeys(
    AppPreferenceKeys.getAllKeys(),
  );

  // Получить настройки по категории
  final securityKeys = prefsService.getKeysByCategory(
    PrefCategory.security,
    AppPreferenceKeys.getAllKeys(),
  );

  // Пример использования в UI
  for (final key in securityKeys) {
    debugPrint('Настройка безопасности: ${key.key}');
    debugPrint('  Можно редактировать: ${key.editable}');
    debugPrint('  Скрыта в UI: ${key.isHiddenUI}');
  }
}

/// Пример провайдера для Riverpod
class PreferencesProviderExample {
  // Provider для PreferencesService
  // final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  //   throw UnimplementedError('Должен быть инициализирован в main()');
  // });

  // Provider для SecureStorageService
  // final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  //   return SecureStorageService.init();
  // });

  // Пример провайдера для конкретной настройки
  // final themeModeProvider = FutureProvider<String>((ref) async {
  //   final prefs = ref.watch(preferencesServiceProvider);
  //   return prefs.getOrDefault(AppPreferenceKeys.themeMode, 'system');
  // });
}
