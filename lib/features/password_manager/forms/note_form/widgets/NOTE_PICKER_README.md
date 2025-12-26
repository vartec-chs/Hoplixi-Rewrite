# Note Picker Modal - Модальное окно выбора заметок

## Описание

Модальное окно для выбора заметок, реализованное с использованием WoltModalSheet
и Riverpod state management. Поддерживает поиск и пагинацию.

## Основные компоненты

### 1. NotePickerResult

Класс результата выбора заметки:

```dart
class NotePickerResult {
  final String id;    // ID выбранной заметки
  final String name;  // Название заметки
}
```

### 2. State Providers

#### notePickerFilterProvider

Provider для управления фильтром заметок:

- Хранит состояние фильтра (поисковый запрос, пагинация)
- Методы:
  - `updateQuery(String query)` - обновить поисковый запрос
  - `incrementOffset()` - увеличить offset для загрузки следующей страницы
  - `reset()` - сбросить фильтр к начальному состоянию

#### notePickerDataProvider

Provider для управления загруженными данными:

- Хранит список заметок, флаги hasMore и isLoadingMore
- Методы:
  - `loadInitial()` - загрузить первую страницу
  - `loadMore()` - загрузить следующую страницу (пагинация)

### 3. NotePickerData

Класс состояния данных:

```dart
class NotePickerData {
  final List<NoteCardDto> notes;      // Список загруженных заметок
  final bool hasMore;                 // Есть ли еще данные для загрузки
  final bool isLoadingMore;           // Идет ли загрузка следующей страницы
}
```

## Использование

### Базовое использование

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/widgets/note_picker_modal.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final result = await showNotePickerModal(context, ref);
        if (result != null) {
          print('Выбрана заметка: ${result.name} (ID: ${result.id})');
          // Используйте результат...
        }
      },
      child: const Text('Выбрать заметку'),
    );
  }
}
```

### Пример в StatefulWidget

```dart
class MyForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyForm> createState() => _MyFormState();
}

class _MyFormState extends ConsumerState<MyForm> {
  NotePickerResult? _selectedNote;

  Future<void> _selectNote() async {
    final result = await showNotePickerModal(context, ref);
    if (result != null && mounted) {
      setState(() {
        _selectedNote = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedNote != null)
          Text('Выбрано: ${_selectedNote!.name}'),
        ElevatedButton(
          onPressed: _selectNote,
          child: const Text('Выбрать заметку'),
        ),
      ],
    );
  }
}
```

## Функциональность

### Поиск

- Поиск выполняется по полям: `title`, `description`, `content`
- Поиск регистронезависимый
- Результаты обновляются автоматически при изменении запроса

### Пагинация

- Автоматическая подгрузка при прокрутке до конца списка
- Размер страницы: 20 элементов
- Отображение индикатора загрузки при подгрузке следующей страницы

### Отображение

- Список заметок с иконками
- Отображение категории (если есть)
- Отображение описания (если есть)
- Иконка звезды для избранных заметок
- Пустое состояние при отсутствии результатов

## Архитектура

### Разделение провайдеров

Следуя best practices, состояние разделено на два провайдера:

1. **notePickerFilterProvider** - отвечает за фильтрацию

   - Управляет параметрами запроса (query, offset, limit)
   - Не зависит от данных

2. **notePickerDataProvider** - отвечает за данные
   - Загружает и хранит список заметок
   - Использует фильтр из notePickerFilterProvider

Это позволяет:

- Изменять фильтр без перезагрузки данных
- Легко тестировать каждый провайдер отдельно
- Переиспользовать логику фильтрации

### Использование DAO

Модальное окно использует `NoteFilterDao` для получения данных:

- Метод `getFiltered(filter)` - получить отфильтрованные заметки
- Метод `countFiltered(filter)` - подсчитать общее количество

## Зависимости

- `flutter_riverpod` - state management
- `wolt_modal_sheet` - модальное окно
- `hoplixi/main_store` - доступ к базе данных
- `hoplixi/shared/ui` - UI компоненты (TextField, Button)

## Примечания

- Модальное окно автоматически сбрасывает состояние при каждом открытии
- Требуется открытая база данных для работы
- При ошибках отображаются toast-уведомления
- Поддерживает как светлую, так и темную темы
