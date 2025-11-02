import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки Dashboard'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Общие настройки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Автоблокировка'),
                  subtitle: const Text('Автоматически блокировать хранилище'),
                  value: true,
                  onChanged: (value) {
                    // Изменить настройку
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Показывать иконки'),
                  subtitle: const Text('Отображать иконки сайтов'),
                  value: true,
                  onChanged: (value) {
                    // Изменить настройку
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Таймаут блокировки'),
                  subtitle: const Text('5 минут'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Открыть настройку
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Безопасность', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Изменить мастер-пароль'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Открыть смену пароля
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Резервное копирование'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Открыть резервное копирование
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Проверка безопасности'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Запустить проверку
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Импорт/Экспорт', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Импорт данных'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Открыть импорт
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Экспорт данных'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Открыть экспорт
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
