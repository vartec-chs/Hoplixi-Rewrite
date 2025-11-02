import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/ui/status_bar.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';

/// Пример использования StatusBar с отображением состояния БД
class StatusBarExampleScreen extends ConsumerWidget {
  const StatusBarExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusBar = ref.read(statusBarStateProvider.notifier);
    final mainStore = ref.read(mainStoreProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('StatusBar Example')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Управление сообщениями
              const Text(
                'Управление сообщениями:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: double.infinity),
              ElevatedButton(
                onPressed: () => statusBar.updateMessage('Готово к работе'),
                child: const Text('Обычное сообщение'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.showLoading('Загрузка данных...'),
                child: const Text('Показать загрузку'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.showSuccess('Операция выполнена!'),
                child: const Text('Успех'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.showError('Произошла ошибка'),
                child: const Text('Ошибка'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.showWarning('Внимание!'),
                child: const Text('Предупреждение'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.showInfo('Информация'),
                child: const Text('Инфо'),
              ),
              ElevatedButton(
                onPressed: () {
                  statusBar.setRightContent(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14),
                        const SizedBox(width: 4),
                        const Text('User', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                  statusBar.updateMessage('С правым контентом');
                },
                child: const Text('С доп. контентом'),
              ),
              ElevatedButton(
                onPressed: () => statusBar.clear(),
                child: const Text('Очистить'),
              ),

              // Управление БД
              const SizedBox(width: double.infinity, height: 16),
              const Text(
                'Управление БД (для демонстрации статуса):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: double.infinity),
              ElevatedButton.icon(
                onPressed: () async {
                  statusBar.showLoading('Создание БД...');
                  // Пример - в реальном приложении путь выбирается пользователем
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final success = await mainStore.createStore(
                    CreateStoreDto(
                      path: 'test_db_$timestamp.db',
                      name: 'Test Database',
                      description: 'Тестовая база данных',
                      password: 'test123',
                    ),
                  );
                  if (success) {
                    statusBar.showSuccess('БД создана успешно');
                  } else {
                    statusBar.showError('Не удалось создать БД');
                  }
                },
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Создать тестовую БД'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  mainStore.lockStore();
                  statusBar.showWarning('БД заблокирована');
                },
                icon: const Icon(Icons.lock),
                label: const Text('Заблокировать БД'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  statusBar.showLoading('Закрытие БД...');
                  final success = await mainStore.closeStore();
                  if (success) {
                    statusBar.showInfo('БД закрыта');
                  }
                },
                icon: const Icon(Icons.close),
                label: const Text('Закрыть БД'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const StatusBar(),
    );
  }
}
