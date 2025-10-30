import 'dart:io';
import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/features/logs_viewer/models/log_parser.dart';

// ============================================================================
// Notifier classes for state management
// ============================================================================

/// Notifier для управления выбранным файлом логов
class SelectedLogFileNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void setFile(File? file) {
    state = file;
  }
}

/// Notifier для управления фильтром по уровню
class LogLevelFilterNotifier extends Notifier<LogLevel?> {
  @override
  LogLevel? build() => null;

  void setLevel(LogLevel? level) {
    state = level;
  }
}

/// Notifier для управления фильтром по тегу
class LogTagFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTag(String? tag) {
    state = tag;
  }
}

/// Notifier для управления поисковым запросом
class LogSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

/// Notifier для управления выбранным отчетом о падении
class SelectedCrashReportNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void setFile(File? file) {
    state = file;
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Провайдер для получения списка файлов логов
final logFilesProvider = FutureProvider<List<File>>((ref) async {
  final dir = Directory(await AppPaths.appLogsPath);
  if (!await dir.exists()) {
    return [];
  }

  return dir
      .listSync()
      .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
      .cast<File>()
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path)); // Новые файлы первыми
});

/// Провайдер для содержимого выбранного файла логов
final selectedLogFileProvider =
    NotifierProvider<SelectedLogFileNotifier, File?>(
      SelectedLogFileNotifier.new,
    );

/// Провайдер для парсированного содержимого логов
final parsedLogsProvider = FutureProvider<List<dynamic>>((ref) async {
  final selectedFile = ref.watch(selectedLogFileProvider);

  if (selectedFile == null) {
    return [];
  }

  try {
    final content = await selectedFile.readAsString();
    return LogParser.parseJsonl(content);
  } catch (e) {
    return [];
  }
});

/// Провайдер для фильтрации логов по уровню
final logLevelFilterProvider =
    NotifierProvider<LogLevelFilterNotifier, LogLevel?>(
      LogLevelFilterNotifier.new,
    );

/// Провайдер для фильтрации логов по тегу
final logTagFilterProvider = NotifierProvider<LogTagFilterNotifier, String?>(
  LogTagFilterNotifier.new,
);

/// Провайдер для фильтрации логов по поисковому запросу
final logSearchQueryProvider = NotifierProvider<LogSearchQueryNotifier, String>(
  LogSearchQueryNotifier.new,
);

/// Провайдер для отфильтрованных логов
final filteredLogsProvider = FutureProvider<List<LogEntry>>((ref) async {
  final logs = await ref.watch(parsedLogsProvider.future);
  final levelFilter = ref.watch(logLevelFilterProvider);
  final tagFilter = ref.watch(logTagFilterProvider);
  final searchQuery = ref.watch(logSearchQueryProvider).toLowerCase();

  final logEntries = logs.whereType<LogEntry>().toList();

  return logEntries.where((log) {
      // Фильтр по уровню
      if (levelFilter != null && log.level != levelFilter) {
        return false;
      }

      // Фильтр по тегу
      if (tagFilter != null && log.tag != tagFilter) {
        return false;
      }

      // Фильтр по поисковому запросу
      if (searchQuery.isNotEmpty) {
        final messageMatch = log.message.toLowerCase().contains(searchQuery);
        final tagMatch = (log.tag ?? '').toLowerCase().contains(searchQuery);
        final errorMatch = (log.error?.toString() ?? '').toLowerCase().contains(
          searchQuery,
        );

        return messageMatch || tagMatch || errorMatch;
      }

      return true;
    }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Новые логи первыми
});

/// Провайдер для получения уникальных тегов
final availableTagsProvider = FutureProvider<List<String>>((ref) async {
  final logs = await ref.watch(parsedLogsProvider.future);
  final tags =
      logs
          .whereType<LogEntry>()
          .map((log) => log.tag)
          .where((tag) => tag != null)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

  return tags;
});

/// Провайдер для получения файлов отчетов о падениях
final crashReportsProvider = FutureProvider<List<File>>((ref) async {
  final dir = Directory(await AppPaths.appCrashReportsPath);
  if (!await dir.exists()) {
    return [];
  }

  return dir
      .listSync()
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>()
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path)); // Новые файлы первыми
});

/// Провайдер для выбранного отчета о падении
final selectedCrashReportProvider =
    NotifierProvider<SelectedCrashReportNotifier, File?>(
      SelectedCrashReportNotifier.new,
    );

/// Провайдер для содержимого отчета о падении
final crashReportContentProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final selectedFile = ref.watch(selectedCrashReportProvider);

  if (selectedFile == null) {
    return null;
  }

  try {
    final content = await selectedFile.readAsString();
    return Map<String, dynamic>.from(jsonDecode(content));
  } catch (e) {
    return null;
  }
});
