# Logs Viewer Feature

Полнофункциональный просмотр логов приложения с поддержкой фильтрации, поиска и просмотра отчетов о падениях.

## Структура

```
lib/features/logs_viewer/
├── models/
│   └── log_parser.dart          # Парсер JSONL логов
├── providers/
│   └── logs_provider.dart       # Riverpod провайдеры
├── screens/
│   ├── logs_tabs_screen.dart    # Главный экран с навигацией
│   ├── logs_viewer_screen.dart  # Просмотр логов
│   └── crash_reports_screen.dart # Просмотр отчетов о падениях
├── widgets/
│   ├── log_entry_tile.dart      # Карточка лога
│   └── logs_filter_bar.dart     # Панель фильтров
└── logs_viewer.dart             # Главный экспорт
```

## Возможности

### 1. Просмотр логов
- Выбор файла логов из списка
- Отображение всех записей с цветовой кодировкой по уровню
- Развертывание записи для просмотра полной информации
- Эмодзи для быстрой визуальной идентификации уровня лога

### 2. Фильтрация и поиск
- Фильтр по уровню логирования (DEBUG, INFO, WARNING, ERROR, TRACE, FATAL)
- Фильтр по тегу (если присутствуют)
- Полнотекстовый поиск по сообщениям, тегам и ошибкам
- Очистка всех фильтров одной кнопкой

### 3. Информация о логах
- Время создания лога
- Уровень логирования
- Тег (если присутствует)
- Сообщение
- Информация об ошибке (если есть)
- Stack Trace (если есть)
- Дополнительные данные (если есть)

### 4. Отчеты о падениях
- Список файлов отчетов о падениях
- Информация о платформе и устройстве
- Полная информация об ошибке и stack trace
- Сведения о сессии при которой произошло падение

## Использование

### Добавление в маршрутизацию

```dart
// В вашем router.dart или аналогичном файле

GoRoute(
  path: '/logs',
  builder: (context, state) => const LogsTabsScreen(),
),
```

### Интеграция с навигацией

```dart
// Переход на экран просмотра логов
context.go('/logs');

// Или если используете Navigator
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const LogsTabsScreen(),
  ),
);
```

## Структура файла логов (JSONL)

Каждая строка содержит JSON объект:

```json
{
  "sessionId": "uuid",
  "timestamp": "2025-10-31T12:34:56.789Z",
  "level": "INFO",
  "message": "Application started",
  "tag": "AppLogger",
  "error": null,
  "stackTrace": null,
  "additionalData": null
}
```

### События сессии

```json
{
  "type": "session_start",
  "timestamp": "2025-10-31T12:34:56.789Z",
  "session": {
    "id": "uuid",
    "startTime": "2025-10-31T12:34:56.789Z",
    "deviceInfo": {
      "deviceId": "device-id",
      "platform": "Android",
      "platformVersion": "14.0",
      "deviceModel": "Pixel 8",
      "appVersion": "1.0.0",
      ...
    }
  }
}
```

## Парсер логов

### LogParser

Класс `LogParser` предоставляет методы для парсинга JSONL:

```dart
// Парсить одну строку
final entry = LogParser.parseLine(jsonlLine);

// Парсить весь файл
final entries = LogParser.parseJsonl(fileContent);
```

Парсер автоматически определяет тип записи:
- `LogEntry` - обычная запись лога
- `SessionEvent` - событие сессии (начало/конец)

## Riverpod провайдеры

### Основные провайдеры

- `logFilesProvider` - Список файлов логов
- `selectedLogFileProvider` - Выбранный файл логов
- `parsedLogsProvider` - Парсированное содержимое файла
- `filteredLogsProvider` - Отфильтрованные логи

### Фильтры

- `logLevelFilterProvider` - Фильтр по уровню
- `logTagFilterProvider` - Фильтр по тегу
- `logSearchQueryProvider` - Поисковый запрос

### Дополнительные провайдеры

- `availableTagsProvider` - Список доступных тегов
- `crashReportsProvider` - Список отчетов о падениях
- `selectedCrashReportProvider` - Выбранный отчет
- `crashReportContentProvider` - Содержимое отчета

## Кастомизация

### Изменение цветов логов

В `log_entry_tile.dart`:

```dart
Color _getLogLevelColor() {
  switch (widget.entry.level) {
    case LogLevel.debug:
      return Colors.grey; // Измените здесь
    // ...
  }
}
```

### Изменение эмодзи

В `log_entry_tile.dart`:

```dart
String _getLogLevelEmoji() {
  switch (widget.entry.level) {
    case LogLevel.debug:
      return '🐛'; // Измените здесь
    // ...
  }
}
```

### Изменение формата времени

Найдите `DateFormat` в `log_entry_tile.dart`:

```dart
final timeStr = DateFormat('HH:mm:ss.SSS').format(widget.entry.timestamp);
// Измените формат на нужный вам
```

## Зависимости

- `flutter_riverpod` - Управление состоянием
- `intl` - Форматирование дат
- `path_provider` - Доступ к директориям приложения

## Производительность

- Логи парсируются асинхронно
- Фильтрация происходит в памяти (подходит для разумного количества логов)
- Для больших файлов логов рассмотрите реализацию пагинации

## Возможные улучшения

- [ ] Экспорт логов (CSV, JSON)
- [ ] Пагинация при большом количестве записей
- [ ] Фильтрация по диапазону времени
- [ ] Группировка логов по сессиям
- [ ] Статистика по уровням логирования
- [ ] Отправка логов на сервер
- [ ] Шифрование чувствительных логов

## Пример интеграции с главным экраном

```dart
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Просмотр логов'),
            leading: const Icon(Icons.description),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LogsTabsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```
