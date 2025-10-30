# App Preferences

Типизированные обертки для `shared_preferences` и `flutter_secure_storage` с поддержкой категорий и настройками видимости для UI.

## Возможности

✅ **Типизированные ключи** - безопасность типов на уровне компиляции  
✅ **Категории настроек** - группировка настроек для UI  
✅ **Контроль видимости** - скрытие системных настроек от пользователя  
✅ **Контроль редактирования** - запрет редактирования критичных настроек  
✅ **Удобное API** - простые методы для работы с настройками  
✅ **Поддержка JSON** - сохранение и чтение сложных объектов  

## Структура

```
lib/core/app_preferences/
├── pref_category.dart          # Enum категорий настроек
├── pref_key.dart               # Типизированный ключ для SharedPreferences
├── secure_key.dart             # Типизированный ключ для FlutterSecureStorage
├── preferences_service.dart    # Сервис для работы с SharedPreferences
├── secure_storage_service.dart # Сервис для работы с FlutterSecureStorage
├── app_preference_keys.dart    # Примеры ключей приложения
├── usage_examples.dart         # Примеры использования
└── app_preferences.dart        # Главный экспорт
```

## Использование

### 1. Импорт

```dart
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
```

### 2. Инициализация

```dart
// В main() или при запуске приложения
final prefsService = await PreferencesService.init();
final secureStorage = SecureStorageService.init();
```

### 3. Определение ключей

```dart
// Ключ для SharedPreferences
const themeMode = PrefKey<String>(
  'theme_mode',
  category: PrefCategory.appearance,
  editable: true,
  isHiddenUI: false,
);

// Ключ для FlutterSecureStorage
const masterPassword = SecureKey<String>(
  'master_password',
  category: PrefCategory.security,
  editable: false,
  isHiddenUI: true,
);
```

### 4. Работа с SharedPreferences

```dart
// Сохранение
await prefsService.set(themeMode, 'dark');
await prefsService.setInt(autoLockTimeout, 300);
await prefsService.setBool(biometricEnabled, true);

// Чтение
final theme = prefsService.get(themeMode);
final timeout = prefsService.getOrDefault(autoLockTimeout, 60);

// Удаление
await prefsService.remove(themeMode);

// Проверка
if (prefsService.containsKey(themeMode)) {
  // ключ существует
}
```

### 5. Работа с FlutterSecureStorage

```dart
// Сохранение
await secureStorage.setString(masterPassword, 'secret123');
await secureStorage.setInt(pinAttempts, 0);

// Чтение
final password = await secureStorage.getString(masterPassword);
final attempts = await secureStorage.getOrDefault(pinAttempts, 0);

// Удаление
await secureStorage.remove(masterPassword);

// Проверка
if (await secureStorage.containsKey(masterPassword)) {
  // ключ существует
}
```

### 6. Работа с JSON

```dart
// SharedPreferences
await prefsService.setJson(userSettings, {
  'theme': 'dark',
  'language': 'ru',
});

final settings = prefsService.getJson(userSettings);

// FlutterSecureStorage
await secureStorage.setJson(sessionData, {
  'userId': '12345',
  'token': 'abc-def',
});

final session = await secureStorage.getJson(sessionData);
```

### 7. Фильтрация ключей для UI

```dart
// Получить все видимые настройки
final visible = prefsService.getVisibleKeys(allKeys);

// Получить редактируемые настройки
final editable = prefsService.getEditableKeys(allKeys);

// Получить настройки по категории
final securitySettings = prefsService.getKeysByCategory(
  PrefCategory.security,
  allKeys,
);
```

## Категории настроек

```dart
enum PrefCategory {
  general,        // Общие настройки
  security,       // Безопасность
  appearance,     // Внешний вид
  sync,           // Синхронизация
  notifications,  // Уведомления
  backup,         // Резервное копирование
  system,         // Системные настройки
}
```

## Свойства ключей

- **key** - строковый идентификатор для хранения
- **isHiddenUI** - скрыть ли настройку в UI (для системных настроек)
- **editable** - можно ли редактировать в UI (для критичных настроек)
- **category** - категория для группировки в UI

## Поддерживаемые типы

### SharedPreferences
- `String`
- `int`
- `double`
- `bool`
- `List<String>`
- `Map<String, dynamic>` (через JSON)

### FlutterSecureStorage
- `String`
- `int`
- `double`
- `bool`
- `Map<String, dynamic>` (через JSON)
- `List<T>` (через JSON)

## Примеры

См. файл `usage_examples.dart` для полных примеров использования.

## Лицензия

Часть приложения Hoplixi - Password Manager
