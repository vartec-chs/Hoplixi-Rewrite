import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/theme/theme_switcher.dart';
import 'package:hoplixi/features/settings/providers/settings_provider.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_tile.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_section_card.dart';

/// Секция настроек внешнего вида
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsSectionCard(
      title: 'Внешний вид',
      children: [SettingsThemeSwitcher()],
    );
  }
}

/// Секция общих настроек
class GeneralSettingsSection extends ConsumerWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final language = settings[AppKeys.language.key] as String? ?? 'ru';

    return SettingsSectionCard(
      title: 'Общие',
      children: [
        SettingsTile(
          title: 'Язык',
          subtitle: _getLanguageName(language),
          leading: const Icon(Icons.language),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(context, ref, notifier),
        ),
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
  ) async {
    final languages = {'ru': 'Русский', 'en': 'English'};

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      await notifier.setString(AppKeys.language.key, result);
    }
  }
}

/// Секция настроек безопасности
class SecuritySettingsSection extends ConsumerWidget {
  const SecuritySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final biometricEnabled =
        settings[AppKeys.biometricEnabled.key] as bool? ?? false;
    final autoLockTimeout =
        settings[AppKeys.autoLockTimeout.key] as int? ?? 300;

    return SettingsSectionCard(
      title: 'Безопасность',
      children: [
        SettingsSwitchTile(
          title: 'Биометрическая аутентификация',
          subtitle: 'Использовать отпечаток пальца или Face ID',
          leading: const Icon(Icons.fingerprint),
          value: biometricEnabled,
          onChanged: (value) => notifier.setBoolWithBiometric(
            AppKeys.biometricEnabled.key,
            value,
            reason: 'Подтвердите изменение настройки биометрии',
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Таймаут автоблокировки',
          subtitle: _formatTimeout(autoLockTimeout),
          leading: const Icon(Icons.lock_clock),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              _showTimeoutDialog(context, ref, notifier, autoLockTimeout),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Изменить PIN-код',
          subtitle: 'Установить новый PIN-код',
          leading: const Icon(Icons.pin),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showChangePinDialog(context, ref, notifier),
        ),
      ],
    );
  }

  String _formatTimeout(int seconds) {
    if (seconds == 0) return 'Отключено';
    if (seconds < 60) return '$seconds сек';
    final minutes = seconds ~/ 60;
    return '$minutes мин';
  }

  Future<void> _showTimeoutDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
    int currentTimeout,
  ) async {
    final timeouts = {
      0: 'Отключено',
      30: '30 секунд',
      60: '1 минута',
      300: '5 минут',
      600: '10 минут',
      1800: '30 минут',
    };

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Таймаут автоблокировки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: timeouts.entries.map((entry) {
            return RadioListTile<int>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: currentTimeout,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      await notifier.setInt(AppKeys.autoLockTimeout.key, result);
    }
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить PIN-код'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите новый PIN-код (4-8 цифр)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'PIN-код',
                hintText: '****',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await notifier.setStringWithBiometric(
        AppKeys.pinCode.key,
        result,
        reason: 'Подтвердите изменение PIN-кода',
      );
    }
  }
}

/// Секция настроек синхронизации
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final autoSyncEnabled =
        settings[AppKeys.autoSyncEnabled.key] as bool? ?? false;
    final lastSyncTime = settings[AppKeys.lastSyncTime.key] as int?;

    return SettingsSectionCard(
      title: 'Синхронизация',
      children: [
        SettingsSwitchTile(
          title: 'Автоматическая синхронизация',
          subtitle: 'Синхронизировать данные автоматически',
          leading: const Icon(Icons.sync),
          value: autoSyncEnabled,
          onChanged: (value) =>
              notifier.setBool(AppKeys.autoSyncEnabled.key, value),
        ),
        if (lastSyncTime != null) ...[
          const Divider(height: 1),
          SettingsTile(
            title: 'Последняя синхронизация',
            subtitle: _formatLastSync(lastSyncTime),
            leading: const Icon(Icons.update),
          ),
        ],
      ],
    );
  }

  String _formatLastSync(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return '${diff.inHours} ч назад';
    return '${diff.inDays} дн назад';
  }
}

/// Секция настроек резервного копирования
class BackupSettingsSection extends ConsumerWidget {
  const BackupSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final autoBackupEnabled =
        settings[AppKeys.autoBackupEnabled.key] as bool? ?? false;
    final backupPath = settings[AppKeys.backupPath.key] as String?;

    return SettingsSectionCard(
      title: 'Резервное копирование',
      children: [
        SettingsSwitchTile(
          title: 'Автоматическое резервное копирование',
          subtitle: 'Создавать резервные копии автоматически',
          leading: const Icon(Icons.backup),
          value: autoBackupEnabled,
          onChanged: (value) =>
              notifier.setBool(AppKeys.autoBackupEnabled.key, value),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Путь резервных копий',
          subtitle: backupPath ?? 'Не установлен',
          leading: const Icon(Icons.folder),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBackupPathDialog(context, ref, notifier),
        ),
      ],
    );
  }

  Future<void> _showBackupPathDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Путь резервных копий'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите путь для сохранения резервных копий'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Путь',
                hintText: '/path/to/backup',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await notifier.setString(AppKeys.backupPath.key, result);
    }
  }
}
