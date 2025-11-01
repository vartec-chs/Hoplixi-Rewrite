/// Пример использования Logs Viewer Feature
library;

import 'package:flutter/material.dart';
import 'package:hoplixi/features/logs_viewer/logs_viewer.dart';

// ============================================================================
// Добавление в маршрутизацию (router.dart или go_router setup)
// ============================================================================

/*
// Пример с go_router:

import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';

final router = GoRouter(
  routes: [
    // ... другие маршруты ...
    
    GoRoute(
      path: '/logs',
      builder: (context, state) => const LogsTabsScreen(),
    ),
  ],
);

// Переход на экран логов:
context.go('/logs');
*/

// ============================================================================
// Добавление в меню настроек
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Просмотр логов'),
            subtitle: const Text('Логи приложения и отчеты о падениях'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LogsTabsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Использование провайдеров программно
// ============================================================================

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';

// Примеры использования провайдеров:

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получить список файлов логов
    final logFiles = ref.watch(logFilesProvider);

    // Получить текущий фильтр по уровню
    final levelFilter = ref.watch(logLevelFilterProvider);

    // Установить фильтр по уровню
    ref.read(logLevelFilterProvider.notifier).setLevel(LogLevel.error);

    // Выполнить поиск
    ref.read(logSearchQueryProvider.notifier).setQuery('error');

    // Получить отфильтрованные логи
    final filteredLogs = ref.watch(filteredLogsProvider);

    return logFiles.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
      data: (files) => Text('Найдено файлов: ${files.length}'),
    );
  }
}
*/

// ============================================================================
// Очистка фильтров программно
// ============================================================================

/*
void clearAllFilters(WidgetRef ref) {
  ref.read(logLevelFilterProvider.notifier).setLevel(null);
  ref.read(logTagFilterProvider.notifier).setTag(null);
  ref.read(logSearchQueryProvider.notifier).setQuery('');
}
*/

// ============================================================================
// Экспорт логов
// ============================================================================

/*
import 'dart:io';
import 'dart:convert';
import 'package:hoplixi/core/app_paths.dart';

// Пример: экспортировать логи в текстовый файл
Future<File> exportLogsToFile() async {
  final logFiles = await Directory(await AppPaths.appLogsPath).list().toList();
  
  final exportFile = File('${await AppPaths.appLogsPath}/export.txt');
  
  for (final file in logFiles.whereType<File>()) {
    if (file.path.endsWith('.jsonl')) {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      for (final line in lines.where((l) => l.isNotEmpty)) {
        final json = jsonDecode(line);
        exportFile.writeAsStringSync(
          '${json['timestamp']} [${json['level']}] ${json['message']}\n',
          mode: FileMode.append,
        );
      }
    }
  }
  
  return exportFile;
}
*/

// ============================================================================
// Кастомизация
// ============================================================================

/*
// Для изменения цветов, эмодзи или формата времени:
// Отредактируйте файлы:
// - lib/features/logs_viewer/widgets/log_entry_tile.dart
// - Методы _getLogLevelColor() и _getLogLevelEmoji()
// - DateFormat в методе build()
*/
