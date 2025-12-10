# App Preferences

Унифицированные обертки для `shared_preferences` и `flutter_secure_storage` с единым API и автоматическим выбором хранилища.

## Возможности

✅ **Унифицированный ключ AppKey** - один класс для обоих типов хранилищ  
✅ **Флаг isProtected** - автоматический выбор между SharedPreferences и SecureStorage  
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
├── app_key.dart                # Унифицированный типизированный ключ
├── app_storage_service.dart    # Унифицированный сервис хранения
├── app_preference_keys.dart    # Ключи приложения
├── settings_key.dart           # UI-ориентированные ключи
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
final storage = await AppStorageService.init(
  secureStorage: const FlutterSecureStorage(),
);
```

### 3. Определение ключей

```dart
// Обычный ключ (SharedPreferences)
const themeMode = AppKey<String>(
  'theme_mode',
  category: PrefCategory.appearance,
  editable: true,
  isHiddenUI: false,
);

// Защищённый ключ (FlutterSecureStorage)
const masterPassword = AppKey<String>(
  'master_password',
  isProtected: true,  // <- Ключевой флаг!
  category: PrefCategory.security,
  editable: false,
  isHiddenUI: true,
);
```

### 4. Работа с хранилищем

```dart
// Сохранение (автоматически выбирает хранилище)
await storage.set(themeMode, 'dark');
await storage.setInt(autoLockTimeout, 300);
await storage.setBool(biometricEnabled, true);

// Защищённые данные автоматически идут в SecureStorage
await storage.setString(masterPassword, 'secret123');

// Чтение
final theme = await storage.get(themeMode);
final timeout = await storage.getOrDefault(autoLockTimeout, 60);

// Удаление
await storage.remove(themeMode);

// Проверка
if (await storage.containsKey(themeMode)) {
  // ключ существует
}
```

### 5. Работа с JSON

```dart
// Обычные настройки
await storage.setJson(userSettings, {
  'theme': 'dark',
  'language': 'ru',
});

final settings = await storage.getJson(userSettings);

// Защищённые JSON данные
await storage.setJson(sessionData, {
  'userId': '12345',
  'token': 'abc-def',
});

final session = await storage.getJson(sessionData);
```

### 6. Фильтрация ключей для UI

```dart
// Получить все видимые настройки
final visible = storage.getVisibleKeys(AppKeys.getAllKeys());

// Получить редактируемые настройки
final editable = storage.getEditableKeys(AppKeys.getAllKeys());

// Получить настройки по категории
final securitySettings = storage.getKeysByCategory(
  PrefCategory.security,
  AppKeys.getAllKeys(),
);

// Получить только защищённые ключи
final protectedKeys = storage.getProtectedKeys(AppKeys.getAllKeys());
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

## Свойства AppKey

| Свойство | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `key` | `String` | — | Строковый идентификатор для хранения |
| `isProtected` | `bool` | `false` | Использовать SecureStorage вместо SharedPreferences |
| `isHiddenUI` | `bool` | `false` | Скрыть настройку в UI |
| `editable` | `bool` | `true` | Разрешить редактирование в UI |
| `category` | `PrefCategory` | `general` | Категория для группировки |

## Поддерживаемые типы

### Оба хранилища
- `String`
- `int`
- `double`
- `bool`
- `Map<String, dynamic>` (через JSON)

### Только SharedPreferences
- `List<String>` (нативно)

### Только SecureStorage
- `List<T>` (через JSON сериализацию)

## Миграция со старого API

```dart
// Было (старый API)
const themeMode = PrefKey<String>('theme_mode');
const password = SecureKey<String>('password');

final prefsService = await PreferencesService.init();
final secureService = SecureStorageService.init(storage);

await prefsService.setString(themeMode, 'dark');
await secureService.setString(password, 'secret');

// Стало (новый API)
const themeMode = AppKey<String>('theme_mode');
const password = AppKey<String>('password', isProtected: true);

final storage = await AppStorageService.init(secureStorage: storage);

await storage.setString(themeMode, 'dark');
await storage.setString(password, 'secret');  // Автоматически в SecureStorage
```

## Лицензия

Часть приложения Hoplixi - Password Manager
