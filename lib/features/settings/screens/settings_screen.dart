import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/ui/settings_sections.dart';

/// Экран настроек приложения
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Секция внешнего вида
            const AppearanceSettingsSection(),

            const SizedBox(height: 8),

            // Секция общих настроек
            const GeneralSettingsSection(),

            const SizedBox(height: 8),

            // Секция безопасности
            const SecuritySettingsSection(),

            const SizedBox(height: 8),

            // Секция синхронизации
            const SyncSettingsSection(),

            const SizedBox(height: 8),

            // Секция резервного копирования
            const BackupSettingsSection(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
