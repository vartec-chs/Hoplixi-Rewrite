# Password Form Implementation

## Overview
Полная реализация формы создания и редактирования паролей с валидацией и интеграцией в dashboard.

## Structure

```
lib/features/password_manager/dashboard/forms/password_form/
├── models/
│   ├── password_form_state.dart          # Freezed модель состояния формы
│   └── password_form_state.freezed.dart  # Сгенерированный файл
├── providers/
│   └── password_form_provider.dart       # Notifier для управления формой
└── screens/
    └── password_form_screen.dart         # UI экрана формы
```

## Key Features

### 1. **State Management** (`password_form_state.dart`)
- Все поля формы (name, password, login, email, url, description, notes)
- Ошибки валидации для каждого поля
- Связи с категорией и тегами
- Флаги состояния (isLoading, isSaving, isSaved)
- Режим создания/редактирования

### 2. **Business Logic** (`password_form_provider.dart`)
- **Riverpod 3.0 Notifier API**
- Валидация полей в реальном времени
- Инициализация для создания/редактирования
- Сохранение в БД через DAO
- Поддержка тегов через transaction

**Правила валидации:**
- `name`: обязательно, макс 255 символов
- `password`: обязательно, не пустой
- `login/email`: хотя бы одно поле должно быть заполнено
- `email`: валидация формата
- `url`: опционально, валидация формата (http/https)

### 3. **UI Implementation** (`password_form_screen.dart`)
- Все обязательные поля формы
- `CategoryPickerField` для выбора категории (одиночный)
- `TagPickerField` для выбора тегов (множественный)
- Кнопка показа/скрытия пароля
- Кнопки "Отмена" и "Создать/Сохранить"
- Индикатор загрузки
- Toast уведомления об успехе/ошибке

## Routes

```dart
// Создание нового пароля
context.go(AppRoutesPaths.dashboardPasswordCreate);

// Редактирование существующего
context.go(AppRoutesPaths.dashboardPasswordEditWithId(passwordId));
```

Пути определены в:
- `lib/routing/paths.dart`
- `lib/routing/routes.dart`

## Database Integration

### Updated DAO (`password_dao.dart`)
Метод `createPassword` обновлен для работы с тегами:
- Использует транзакцию для атомарности
- Создает запись пароля
- Создает связи в `password_tags` для каждого тега

```dart
Future<String> createPassword(CreatePasswordDto dto) async {
  return await db.transaction(() async {
    final passwordId = await into(passwords).insert(companion);
    
    // Добавляем связи с тегами
    if (dto.tagsIds != null && dto.tagsIds!.isNotEmpty) {
      for (final tagId in dto.tagsIds!) {
        await db.into(db.passwordsTags).insert(...);
      }
    }
    
    return passwordId;
  });
}
```

## Usage Example

```dart
// В dashboard_home_screen.dart при нажатии FAB
FloatingActionButton(
  heroTag: 'dashboard_add_button',
  onPressed: () {
    context.go(AppRoutesPaths.dashboardPasswordCreate);
  },
  child: const Icon(Icons.add),
)

// При клике на карточку для редактирования
onTap: () {
  context.go(AppRoutesPaths.dashboardPasswordEditWithId(password.id));
}
```

## Migration Notes

### Riverpod 3.0 Changes
Провайдер использует новый Notifier API:
- ❌ `AutoDisposeNotifier` удален
- ✅ Используется просто `Notifier<State>`
- ✅ `ref` доступен как свойство (не нужен конструктор)
- ✅ `build()` возвращает начальное состояние

```dart
class PasswordFormNotifier extends Notifier<PasswordFormState> {
  @override
  PasswordFormState build() {
    return const PasswordFormState(isEditMode: false);
  }
  
  // ref доступен напрямую, без конструктора
  void someMethod() {
    final dao = await ref.read(passwordDaoProvider.future);
  }
}
```

## TODO

- [ ] Реализовать загрузку тегов при редактировании (`initForEdit`)
- [ ] Реализовать обновление тегов при редактировании (`save`)
- [ ] Добавить генератор случайных паролей
- [ ] Добавить индикатор силы пароля
- [ ] Добавить копирование пароля в буфер обмена
