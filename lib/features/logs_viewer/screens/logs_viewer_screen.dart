import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';
import 'package:hoplixi/features/logs_viewer/widgets/log_entry_tile.dart';
import 'package:hoplixi/features/logs_viewer/widgets/logs_filter_bar.dart';

/// Главный экран для просмотра логов
class LogsViewerScreen extends ConsumerWidget {
  const LogsViewerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logFiles = ref.watch(logFilesProvider);
    final selectedFile = ref.watch(selectedLogFileProvider);
    final filteredLogs = ref.watch(filteredLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Просмотр логов'), elevation: 2),
      body: logFiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки логов: $error'),
            ],
          ),
        ),
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Файлы логов не найдены'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Список файлов логов
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: files.map((file) {
                      final fileName = file.path.split('\\').last;
                      final isSelected = selectedFile?.path == file.path;

                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: FilterChip(
                          label: Text(fileName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(selectedLogFileProvider.notifier)
                                  .setFile(file);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Фильтры и поиск
              const LogsFilterBar(),
              // Список логов
              Expanded(
                child: filteredLogs.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Ошибка: $error')),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.filter_alt_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('Логи не найдены'),
                            const SizedBox(height: 8),
                            Text(
                              'Выберите файл и примените фильтры',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return LogEntryTile(entry: log);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
