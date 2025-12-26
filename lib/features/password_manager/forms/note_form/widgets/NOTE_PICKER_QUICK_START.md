## Note Picker Modal - Краткое руководство

### Быстрый старт

```dart
import 'package:hoplixi/features/password_manager/forms/note_form/widgets/note_picker_modal.dart';

// В вашем виджете
final result = await showNotePickerModal(context, ref);
if (result != null) {
  print('ID: ${result.id}, Name: ${result.name}');
}
```

### Результат выбора

```dart
class NotePickerResult {
  final String id;    // ID заметки
  final String name;  // Название заметки
}
```

### Возможности

✅ Поиск по названию, описанию и содержимому ✅ Автоматическая пагинация при
прокрутке (20 элементов на страницу) ✅ Отображение категории и тегов ✅
Индикация избранных заметок ✅ Темная/светлая тема

### Архитектура

**Два независимых провайдера:**

- `notePickerFilterProvider` - управление фильтрами
- `notePickerDataProvider` - управление данными

**DAO для доступа к данным:**

- `NoteFilterDao.getFiltered()` - получение заметок
- `NoteFilterDao.countFiltered()` - подсчет количества

### Требования

- Открытая база данных
- `flutter_riverpod` для state management
- `wolt_modal_sheet` для модального окна
