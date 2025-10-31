# HiveBoxManager

Менеджер для управления зашифрованными Hive боксами с автоматическим управлением ключами шифрования через FlutterSecureStorage.

## Возможности

- ✅ Автоматическая генерация и сохранение ключей шифрования
- ✅ Поддержка пользовательских ключей шифрования
- ✅ Управление обычными и ленивыми (LazyBox) боксами
- ✅ Централизованное управление всеми боксами
- ✅ Экспорт/импорт ключей для бэкапа
- ✅ Компактирование боксов
- ✅ Полное логирование операций
- ✅ Безопасное хранение ключей в FlutterSecureStorage

## Установка

Пакет уже интегрирован в проект через DI (Dependency Injection).

### Зависимости

```yaml
dependencies:
  hive_ce: ^2.15.1
  hive_ce_flutter: ^2.3.3
  flutter_secure_storage: ^9.2.4
  get_it: ^8.2.0
```

## Использование

### Получение экземпляра

```dart
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';

final hiveManager = getIt<HiveBoxManager>();
```

### Основные операции

#### 1. Открытие бокса с автоматическим шифрованием

```dart
// Ключ генерируется автоматически и сохраняется в FlutterSecureStorage
final box = await hiveManager.openBox<String>('my_box');

// Использование
await box.put('key', 'value');
final value = box.get('key');

// Закрытие
await hiveManager.closeBox('my_box');
```

#### 2. Открытие бокса с пользовательским ключом

```dart
// Создать свой ключ (32 байта для AES-256)
final customKey = List<int>.generate(32, (index) => index);

final box = await hiveManager.openBox<Map>(
  'secure_box',
  encryptionKey: customKey,
);
```

#### 3. Работа с ленивым боксом (LazyBox)

Ленивые боксы не загружают все данные в память сразу, что экономит ресурсы при работе с большими объемами данных.

```dart
final lazyBox = await hiveManager.openLazyBox<String>('lazy_box');

// Запись
await lazyBox.put('large_data', 'Very large string...');

// Чтение (асинхронное)
final data = await lazyBox.get('large_data');

await hiveManager.closeBox('lazy_box');
```

#### 4. Получение существующего открытого бокса

```dart
// Получить уже открытый бокс
final box = hiveManager.getBox<String>('my_box');

// Проверить, открыт ли бокс
if (hiveManager.isBoxOpen('my_box')) {
  final box = hiveManager.getBox<String>('my_box');
}
```

#### 5. Удаление бокса

```dart
// Удаляет бокс с диска и его ключ шифрования
await hiveManager.deleteBox('my_box');

// Проверить существование
final exists = await hiveManager.boxExists('my_box');
```

#### 6. Управление всеми боксами

```dart
// Получить список всех боксов
final allBoxNames = await hiveManager.getAllBoxNames();

// Закрыть все боксы
await hiveManager.closeAll();

// Удалить все боксы и ключи
await hiveManager.deleteAllBoxes();
```

#### 7. Экспорт и импорт ключей (для бэкапа)

```dart
// Экспортировать ключ шифрования
final exportedKey = await hiveManager.exportBoxKey('important_box');
// Сохранить exportedKey в безопасном месте

// Импортировать ключ
await hiveManager.importBoxKey('important_box', exportedKey!);

// Теперь можно открыть бокс с восстановленным ключом
final box = await hiveManager.openBox<String>('important_box');
```

#### 8. Компактирование бокса

Удаляет неиспользуемое пространство после многократных операций удаления.

```dart
await hiveManager.compactBox('data_box');
```

## Архитектура

### Хранение ключей

Ключи шифрования хранятся в FlutterSecureStorage с префиксом `hive_box_key_`:
- Имя ключа: `hive_box_key_{boxName}`
- Формат: Base64 encoded 256-bit ключ
- Платформы: Android (EncryptedSharedPreferences), iOS (Keychain), Windows (Windows Credentials), Linux, macOS

### Инициализация

HiveBoxManager автоматически инициализируется в `setupDI()`:

```dart
// В di_init.dart
final hiveBoxManager = HiveBoxManager(getIt<FlutterSecureStorage>());
await hiveBoxManager.initialize();
getIt.registerSingleton<HiveBoxManager>(hiveBoxManager);
```

### Путь хранения

Боксы хранятся в директории, возвращаемой `AppPaths.boxDbPath`:
- Windows: `Documents/Hoplixi/box/`
- Android/iOS: Application Support Directory

## API Reference

### Методы

#### `initialize()`
Инициализирует Hive с путем к директории. Вызывается автоматически при настройке DI.

#### `openBox<E>(String boxName, {List<int>? encryptionKey, ...})`
Открывает или создает зашифрованный бокс.
- `boxName`: имя бокса
- `encryptionKey`: пользовательский ключ (опционально)
- Возвращает: `Future<Box<E>>`

#### `openLazyBox<E>(String boxName, {List<int>? encryptionKey, ...})`
Открывает или создает ленивый зашифрованный бокс.
- Возвращает: `Future<LazyBox<E>>`

#### `getBox<E>(String boxName)`
Получает открытый бокс. Выбрасывает исключение, если бокс не открыт.
- Возвращает: `Box<E>`

#### `getLazyBox<E>(String boxName)`
Получает открытый ленивый бокс.
- Возвращает: `LazyBox<E>`

#### `isBoxOpen(String boxName)`
Проверяет, открыт ли бокс.
- Возвращает: `bool`

#### `boxExists(String boxName)`
Проверяет, существует ли бокс на диске.
- Возвращает: `Future<bool>`

#### `closeBox(String boxName)`
Закрывает бокс.
- Возвращает: `Future<void>`

#### `deleteBox(String boxName)`
Удаляет бокс с диска и его ключ шифрования.
- Возвращает: `Future<void>`

#### `closeAll()`
Закрывает все открытые боксы.
- Возвращает: `Future<void>`

#### `deleteAllBoxes()`
Удаляет все боксы и ключи шифрования.
- Возвращает: `Future<void>`

#### `compactBox(String boxName)`
Компактирует бокс для освобождения места.
- Возвращает: `Future<void>`

#### `getAllBoxNames()`
Возвращает список всех боксов с сохраненными ключами.
- Возвращает: `Future<List<String>>`

#### `exportBoxKey(String boxName)`
Экспортирует ключ шифрования бокса в формате Base64.
- Возвращает: `Future<String?>`

#### `importBoxKey(String boxName, String encodedKey)`
Импортирует ключ шифрования из Base64 строки.
- Возвращает: `Future<void>`

## Обработка ошибок

Все методы логируют ошибки через `AppLogger`:

```dart
try {
  final box = await hiveManager.openBox('my_box');
} catch (e) {
  // Ошибка автоматически залогирована
  print('Failed to open box: $e');
}
```

## Примеры использования

Полные примеры использования смотрите в файле:
```
lib/core/services/hive_box_manager_examples.dart
```

## Best Practices

1. **Всегда закрывайте боксы** после использования или закрывайте все при выходе из приложения:
   ```dart
   await hiveManager.closeAll();
   ```

2. **Используйте LazyBox для больших данных** чтобы не загружать всё в память:
   ```dart
   final lazyBox = await hiveManager.openLazyBox('large_data');
   ```

3. **Экспортируйте ключи** для критичных данных перед миграцией/обновлением:
   ```dart
   final key = await hiveManager.exportBoxKey('important_box');
   // Сохраните key в облако или другое безопасное место
   ```

4. **Периодически компактируйте** боксы с частыми операциями удаления:
   ```dart
   await hiveManager.compactBox('cache_box');
   ```

5. **Используйте типизацию** для безопасности:
   ```dart
   final box = await hiveManager.openBox<Map<String, dynamic>>('typed_box');
   ```

## Логирование

Все операции логируются с тегом `HiveBoxManager`:
- `logInfo`: успешные операции
- `logWarning`: предупреждения (попытка закрыть неоткрытый бокс)
- `logError`: ошибки с stack trace

Просмотр логов: используйте встроенный Log Viewer в приложении.

## Безопасность

- ✅ AES-256 шифрование
- ✅ Ключи хранятся в platform-specific защищенном хранилище
- ✅ Автоматическая генерация криптографически стойких ключей
- ✅ Ключи никогда не логируются или не выводятся в консоль
- ✅ Поддержка пользовательских ключей для дополнительной безопасности

## Миграция данных

При необходимости миграции с одного устройства на другое:

1. Экспортируйте ключи всех боксов:
   ```dart
   final boxNames = await hiveManager.getAllBoxNames();
   final keys = <String, String>{};
   for (final name in boxNames) {
     keys[name] = (await hiveManager.exportBoxKey(name))!;
   }
   // Сохраните keys
   ```

2. На новом устройстве импортируйте ключи:
   ```dart
   for (final entry in keys.entries) {
     await hiveManager.importBoxKey(entry.key, entry.value);
   }
   ```

3. Скопируйте файлы боксов в директорию `AppPaths.boxDbPath`

## Troubleshooting

### Бокс не открывается
- Убедитесь, что вызван `initialize()`
- Проверьте логи на наличие ошибок

### Неверный ключ шифрования
- Если ключ был изменен/утерян, бокс нужно удалить и создать заново
- Используйте `exportBoxKey()` для резервного копирования ключей

### Производительность
- Используйте LazyBox для больших данных
- Периодически вызывайте `compactBox()`
- Не храните слишком много боксов открытыми одновременно

## Интеграция с проектом

HiveBoxManager следует архитектуре Hoplixi:
- Логирование через `AppLogger`
- Пути через `AppPaths`
- DI через GetIt
- Безопасное хранилище через `FlutterSecureStorage`

## Лицензия

Часть проекта Hoplixi.
