import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';

/// Экран для просмотра отчетов о падениях
class CrashReportsScreen extends ConsumerWidget {
  const CrashReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crashReports = ref.watch(crashReportsProvider);
    final selectedReport = ref.watch(selectedCrashReportProvider);
    final reportContent = ref.watch(crashReportContentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Отчеты о падениях'), elevation: 2),
      body: crashReports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text('Отчеты о падениях не найдены'),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Список отчетов
              SizedBox(
                width: 300,
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final fileName = report.path.split('\\').last;
                    final isSelected = selectedReport?.path == report.path;

                    return ListTile(
                      title: Text(fileName, overflow: TextOverflow.ellipsis),
                      selected: isSelected,
                      onTap: () {
                        ref
                            .read(selectedCrashReportProvider.notifier)
                            .setFile(report);
                      },
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
              ),
              // Детали отчета
              Expanded(
                child: reportContent.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Ошибка загрузки отчета: $error')),
                  data: (data) {
                    if (data == null) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.select_all,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('Выберите отчет для просмотра деталей'),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Время падения
                          if (data['timestamp'] != null) ...[
                            Text(
                              'Время падения',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data['timestamp'] ?? 'N/A',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Ошибка
                          if (data['error'] != null) ...[
                            Text(
                              'Ошибка',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                data['error'],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.red.shade900,
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Stack trace
                          if (data['stackTrace'] != null) ...[
                            Text(
                              'Stack Trace',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.purple),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  data['stackTrace'],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.purple.shade900,
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Информация о сессии
                          if (data['session'] != null) ...[
                            Text(
                              'Информация о сессии',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            _buildSessionInfo(context, data['session']),
                          ],
                        ],
                      ),
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

  Widget _buildSessionInfo(BuildContext context, Map<String, dynamic> session) {
    final deviceInfo = session['deviceInfo'] ?? {};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Session ID:', session['id'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Платформа:', deviceInfo['platform'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Модель:', deviceInfo['deviceModel'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Версия ОС:', deviceInfo['platformVersion'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Версия приложения:',
            deviceInfo['appVersion'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
