import 'pref_key.dart';
import 'secure_key.dart';
import 'pref_category.dart';

/// Примеры типизированных ключей для SharedPreferences
class AppPreferenceKeys {
  // ==================== Общие настройки ====================

  static const themeMode = PrefKey<String>(
    'theme_mode',
    category: PrefCategory.appearance,
    editable: true,
    isHiddenUI: false,
  );

  static const language = PrefKey<String>(
    'language',
    category: PrefCategory.general,
    editable: true,
    isHiddenUI: false,
  );

  static const isFirstLaunch = PrefKey<bool>(
    'is_first_launch',
    category: PrefCategory.system,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Настройки безопасности ====================

  static const autoLockTimeout = PrefKey<int>(
    'auto_lock_timeout',
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  static const biometricEnabled = PrefKey<bool>(
    'biometric_enabled',
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  static const passwordGeneratorLength = PrefKey<int>(
    'password_generator_length',
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  // ==================== Настройки внешнего вида ====================

  static const fontSize = PrefKey<double>(
    'font_size',
    category: PrefCategory.appearance,
    editable: true,
    isHiddenUI: false,
  );

  static const compactMode = PrefKey<bool>(
    'compact_mode',
    category: PrefCategory.appearance,
    editable: true,
    isHiddenUI: false,
  );

  // ==================== Настройки синхронизации ====================

  static const autoSyncEnabled = PrefKey<bool>(
    'auto_sync_enabled',
    category: PrefCategory.sync,
    editable: true,
    isHiddenUI: false,
  );

  static const lastSyncTime = PrefKey<int>(
    'last_sync_time',
    category: PrefCategory.sync,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Настройки резервного копирования ====================

  static const autoBackupEnabled = PrefKey<bool>(
    'auto_backup_enabled',
    category: PrefCategory.backup,
    editable: true,
    isHiddenUI: false,
  );

  static const backupPath = PrefKey<String>(
    'backup_path',
    category: PrefCategory.backup,
    editable: true,
    isHiddenUI: false,
  );

  // ==================== Системные настройки ====================

  static const appVersion = PrefKey<String>(
    'app_version',
    category: PrefCategory.system,
    editable: false,
    isHiddenUI: true,
  );

  static const deviceId = PrefKey<String>(
    'device_id',
    category: PrefCategory.system,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== JSON примеры ====================

  static const userSettings = PrefKey<Map<String, dynamic>>(
    'user_settings',
    category: PrefCategory.general,
    editable: false,
    isHiddenUI: true,
  );

  static const recentSearches = PrefKey<List<String>>(
    'recent_searches',
    category: PrefCategory.general,
    editable: false,
    isHiddenUI: true,
  );

  /// Получить все ключи (для UI настроек)
  static List<PrefKey> getAllKeys() {
    return [
      themeMode,
      language,
      isFirstLaunch,
      autoLockTimeout,
      biometricEnabled,
      passwordGeneratorLength,
      fontSize,
      compactMode,
      autoSyncEnabled,
      lastSyncTime,
      autoBackupEnabled,
      backupPath,
      appVersion,
      deviceId,
      userSettings,
      recentSearches,
    ];
  }
}

/// Примеры типизированных ключей для FlutterSecureStorage
class AppSecureKeys {
  // ==================== Аутентификация ====================

  static const masterPassword = SecureKey<String>(
    'master_password',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  static const passwordHash = SecureKey<String>(
    'password_hash',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  static const encryptionKey = SecureKey<String>(
    'encryption_key',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  static const biometricKey = SecureKey<String>(
    'biometric_key',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Токены ====================

  static const accessToken = SecureKey<String>(
    'access_token',
    category: PrefCategory.sync,
    editable: false,
    isHiddenUI: true,
  );

  static const refreshToken = SecureKey<String>(
    'refresh_token',
    category: PrefCategory.sync,
    editable: false,
    isHiddenUI: true,
  );

  static const apiKey = SecureKey<String>(
    'api_key',
    category: PrefCategory.sync,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Резервные копии ====================

  static const backupEncryptionKey = SecureKey<String>(
    'backup_encryption_key',
    category: PrefCategory.backup,
    editable: false,
    isHiddenUI: true,
  );

  static const cloudCredentials = SecureKey<String>(
    'cloud_credentials',
    category: PrefCategory.backup,
    editable: false,
    isHiddenUI: true,
  );

  // JSON пример (сериализуется как строка в secure storage)
  static const userSessionData = SecureKey<Map<String, dynamic>>(
    'user_session_data',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== PIN код ====================

  static const pinCode = SecureKey<String>(
    'pin_code',
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  static const pinAttempts = SecureKey<int>(
    'pin_attempts',
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  /// Получить все ключи (для UI настроек)
  static List<SecureKey> getAllKeys() {
    return [
      masterPassword,
      passwordHash,
      encryptionKey,
      biometricKey,
      accessToken,
      refreshToken,
      apiKey,
      backupEncryptionKey,
      cloudCredentials,
      userSessionData,
      pinCode,
      pinAttempts,
    ];
  }
}
