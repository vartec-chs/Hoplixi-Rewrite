# Settings Feature

Модуль для управления настройками приложения с интеграцией биометрической аутентификации, защищенного хранилища и автоматической блокировки.

## Возможности

✅ **Унифицированное хранилище** - автоматический выбор между SharedPreferences и FlutterSecureStorage  
✅ **Биометрическая защита** - настройки с `biometricProtect: true` требуют подтверждения  
✅ **Категории настроек** - группировка для удобного отображения в UI  
✅ **Автоблокировка** - интеграция с `AutoLockProvider` через `auto_lock_timeout`  
✅ **Reactive state** - автоматическое обновление UI при изменении настроек  

## Структура

```
lib/features/settings/
├── screens/
│   └── settings_screen.dart         # Главный экран настроек
├── providers/
│   └── settings_provider.dart       # Riverpod провайдер для управления состоянием
├── ui/
│   ├── settings_sections.dart       # Секции настроек (Внешний вид, Безопасность и т.д.)
│   └── widgets/
│       ├── settings_tile.dart       # Базовые виджеты для элементов настроек
│       └── settings_section_card.dart # Карточка секции настроек
└── settings.dart                     # Barrel file для экспорта
```

## Использование

### 1. Навигация к экрану настроек

```dart
import 'package:go_router/go_router.dart';
import 'package:hoplixi/routing/paths.dart';

// В любом виджете
context.push(AppRoutesPaths.settings);
```

### 2. Работа с провайдером настроек

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/settings.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получить все настройки
    final settings = ref.watch(settingsProvider);
    
    // Получить конкретную настройку
    final notifier = ref.read(settingsProvider.notifier);
    final language = notifier.getSetting<String>(AppKeys.language.key);
    
    return Text('Language: $language');
  }
}
```

### 3. Изменение настроек

```dart
// Простые настройки (без биометрии)
await notifier.setBool(AppKeys.autoSyncEnabled.key, true);
await notifier.setInt(AppKeys.autoLockTimeout.key, 300);
await notifier.setString(AppKeys.language.key, 'en');

// Защищенные настройки (с биометрией)
await notifier.setBoolWithBiometric(
  AppKeys.biometricEnabled.key,
  true,
  reason: 'Подтвердите включение биометрии',
);

await notifier.setStringWithBiometric(
  AppKeys.pinCode.key,
  '1234',
  reason: 'Подтвердите изменение PIN-кода',
);
```

## Категории настроек

### Внешний вид (Appearance)
- **Тема приложения** - переключение между светлой/темной темой через `ThemeSwitcher`

### Общие (General)
- **Язык** - выбор языка интерфейса

### Безопасность (Security)
- **Биометрическая аутентификация** - включение/отключение с подтверждением
- **Таймаут автоблокировки** - время до автоматической блокировки (0 = отключено)
- **PIN-код** - изменение PIN-кода с биометрической защитой

### Синхронизация (Sync)
- **Автоматическая синхронизация** - включение/отключение автосинхронизации
- **Последняя синхронизация** - отображение времени последней синхронизации

### Резервное копирование (Backup)
- **Автоматическое резервное копирование** - включение/отключение
- **Путь резервных копий** - указание директории для бэкапов

## Интеграция с AutoLockProvider

Настройка `auto_lock_timeout` автоматически интегрирована с `AutoLockProvider`:

```dart
// При изменении таймаута в настройках
await notifier.setInt(AppKeys.autoLockTimeout.key, 600); // 10 минут

// AutoLockProvider автоматически:
// 1. Обнаруживает изменение через ref.listen(settingsProvider)
// 2. Обновляет totalDuration в состоянии
// 3. Если значение = 0, останавливает таймер (автоблокировка отключена)
// 4. Если значение > 0, применяет новый таймаут

// Значения таймаута:
// 0 - отключено
// 30 - 30 секунд
// 60 - 1 минута
// 300 - 5 минут (по умолчанию)
// 600 - 10 минут
// 1800 - 30 минут
```

## Добавление новых настроек

### 1. Добавить ключ в AppKeys

```dart
// lib/core/app_preferences/app_preference_keys.dart

static const myNewSetting = AppKey<String>(
  'my_new_setting',
  category: PrefCategory.general,
  editable: true,
  isHiddenUI: false,
  isProtected: false, // true для FlutterSecureStorage
  biometricProtect: false, // true для биометрической защиты
);

// Добавить в getAllKeys()
static List<AppKey> getAllKeys() {
  return [
    // ... existing keys
    myNewSetting,
  ];
}
```

### 2. Добавить UI элемент

```dart
// lib/features/settings/ui/settings_sections.dart

SettingsTile(
  title: 'My New Setting',
  subtitle: settings[AppKeys.myNewSetting.key] as String? ?? 'Default',
  leading: const Icon(Icons.settings),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => _showDialog(context, ref, notifier),
),
```

## Обработка ошибок

```dart
// Биометрическая аутентификация обрабатывается автоматически
// Ошибки отображаются через Toaster:

await notifier.setBoolWithBiometric(
  AppKeys.biometricEnabled.key,
  true,
);

// Возможные сценарии:
// ✅ Success -> Toaster.success('Настройка обновлена')
// ❌ Биометрия недоступна -> Toaster.warning('Биометрия недоступна')
// ❌ Отменено пользователем -> Toaster.info('Отменено')
// ❌ Ошибка аутентификации -> Toaster.error('Ошибка аутентификации')
```

## Примеры интеграции

### Добавление пункта настроек в меню

```dart
ListTile(
  leading: const Icon(Icons.settings),
  title: const Text('Настройки'),
  onTap: () => context.push(AppRoutesPaths.settings),
)
```

### Условное отображение элементов

```dart
class MyFeature extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final autoSyncEnabled = settings[AppKeys.autoSyncEnabled.key] as bool? ?? false;
    
    if (!autoSyncEnabled) {
      return ElevatedButton(
        onPressed: () => manualSync(),
        child: const Text('Синхронизировать'),
      );
    }
    
    return const Text('Автосинхронизация включена');
  }
}
```

### Реакция на изменения настроек

```dart
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() {
    // Слушаем изменения настроек
    ref.listen(settingsProvider, (previous, next) {
      final oldTimeout = previous?[AppKeys.autoLockTimeout.key] as int?;
      final newTimeout = next[AppKeys.autoLockTimeout.key] as int?;
      
      if (oldTimeout != newTimeout) {
        logInfo('Timeout changed: $oldTimeout -> $newTimeout');
        _handleTimeoutChange(newTimeout ?? 300);
      }
    });
    
    return MyState();
  }
}
```

## Best Practices

1. **Всегда используйте AppKeys** - не создавайте строковые ключи напрямую
2. **Используйте категории** - для группировки логически связанных настроек
3. **Защищайте чувствительные данные** - `isProtected: true` для паролей, токенов
4. **Биометрия для критичных настроек** - `biometricProtect: true` для изменений безопасности
5. **Значения по умолчанию** - всегда предоставляйте fallback значения
6. **Перезагрузка настроек** - вызывайте `notifier.reload()` после массовых изменений

## Troubleshooting

### Настройка не сохраняется

```dart
// Проверьте, что ключ добавлен в getAllKeys()
final allKeys = AppKeys.getAllKeys();
final hasKey = allKeys.any((k) => k.key == 'my_key');
print('Key exists: $hasKey');
```

### Биометрия не запрашивается

```dart
// 1. Проверьте, что biometricProtect: true
// 2. Проверьте, что biometric_enabled включен в настройках
// 3. Проверьте доступность биометрии на устройстве

final storage = getIt<AppStorageService>();
final isEnabled = await storage.isBiometricEnabled;
print('Biometric enabled: $isEnabled');
```

### Таймаут автоблокировки не работает

```dart
// Проверьте значение в настройках
final timeout = settings[AppKeys.autoLockTimeout.key] as int?;
print('Current timeout: $timeout'); // 0 = отключено

// Проверьте состояние AutoLockProvider
final autoLockState = ref.read(autoLockProvider);
print('Total duration: ${autoLockState.totalDuration}');
print('Remaining: ${autoLockState.remainingSeconds}');
```
