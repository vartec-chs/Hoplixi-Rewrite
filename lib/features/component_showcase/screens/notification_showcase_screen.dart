import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Экран для демонстрации notification cards
class NotificationShowcaseScreen extends StatefulWidget {
  const NotificationShowcaseScreen({super.key});

  @override
  State<NotificationShowcaseScreen> createState() =>
      _NotificationShowcaseScreenState();
}

class _NotificationShowcaseScreenState
    extends State<NotificationShowcaseScreen> {
  final List<String> _dismissedItems = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Basic Notifications',
          children: [
            const ErrorNotificationCard(
              text: 'Ошибка: не удалось загрузить данные с сервера',
            ),
            const SizedBox(height: 12),
            const SuccessNotificationCard(
              text: 'Успешно: данные сохранены в базе данных',
            ),
            const SizedBox(height: 12),
            const InfoNotificationCard(
              text: 'Информация: доступна новая версия приложения',
            ),
            const SizedBox(height: 12),
            const WarningNotificationCard(
              text: 'Предупреждение: слабое подключение к интернету',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'With Custom Icons',
          children: [
            const ErrorNotificationCard(
              text: 'Ошибка сети',
              icon: Icons.wifi_off,
            ),
            const SizedBox(height: 12),
            const SuccessNotificationCard(
              text: 'Файл загружен',
              icon: Icons.cloud_done,
            ),
            const SizedBox(height: 12),
            const InfoNotificationCard(
              text: 'Обновление доступно',
              icon: Icons.system_update,
            ),
            const SizedBox(height: 12),
            const WarningNotificationCard(
              text: 'Заканчивается место',
              icon: Icons.storage,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'With Dismiss Button',
          children: [
            if (!_dismissedItems.contains('error'))
              ErrorNotificationCard(
                text: 'Ошибка: невозможно подключиться к серверу',
                onDismiss: () {
                  setState(() {
                    _dismissedItems.add('error');
                  });
                },
              ),
            if (!_dismissedItems.contains('error')) const SizedBox(height: 12),
            if (!_dismissedItems.contains('success'))
              SuccessNotificationCard(
                text: 'Операция выполнена успешно',
                onDismiss: () {
                  setState(() {
                    _dismissedItems.add('success');
                  });
                },
              ),
            if (!_dismissedItems.contains('success'))
              const SizedBox(height: 12),
            if (!_dismissedItems.contains('info'))
              InfoNotificationCard(
                text: 'У вас есть новое сообщение',
                icon: Icons.mail,
                onDismiss: () {
                  setState(() {
                    _dismissedItems.add('info');
                  });
                },
              ),
            if (!_dismissedItems.contains('info')) const SizedBox(height: 12),
            if (!_dismissedItems.contains('warning'))
              WarningNotificationCard(
                text: 'Батарея разряжена',
                icon: Icons.battery_alert,
                onDismiss: () {
                  setState(() {
                    _dismissedItems.add('warning');
                  });
                },
              ),
            if (_dismissedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _dismissedItems.clear();
                  });
                },
                child: const Text('Показать все снова'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Different Sizes',
          children: [
            const ErrorNotificationCard(
              text: 'Компактное уведомление',
              padding: EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            const SuccessNotificationCard(text: 'Стандартное уведомление'),
            const SizedBox(height: 12),
            const InfoNotificationCard(
              text: 'Большое уведомление с дополнительным отступом',
              padding: EdgeInsets.all(20),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Different Border Radius',
          children: [
            const WarningNotificationCard(
              text: 'Закругленное уведомление (по умолчанию)',
              borderRadius: 12,
            ),
            const SizedBox(height: 12),
            const ErrorNotificationCard(
              text: 'Сильно закругленное уведомление',
              borderRadius: 24,
            ),
            const SizedBox(height: 12),
            const SuccessNotificationCard(
              text: 'Прямоугольное уведомление',
              borderRadius: 4,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Long Text Example',
          children: [
            const ErrorNotificationCard(
              text:
                  'Произошла критическая ошибка при загрузке данных с удаленного сервера. Пожалуйста, проверьте подключение к интернету и попробуйте еще раз. Если проблема сохраняется, обратитесь в службу поддержки.',
            ),
            const SizedBox(height: 12),
            const InfoNotificationCard(
              text:
                  'Это очень длинное информационное сообщение, которое должно правильно переноситься на несколько строк и корректно отображаться в уведомлении с иконкой и кнопкой закрытия.',
              icon: Icons.info,
              onDismiss: null,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Use Generic Component',
          children: [
            NotificationCard(
              type: NotificationType.error,
              text: 'Базовый компонент с типом error',
              icon: Icons.bug_report,
              onDismiss: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Dismissed!')));
              },
            ),
            const SizedBox(height: 12),
            NotificationCard(
              type: NotificationType.success,
              text: 'Базовый компонент с типом success',
              onDismiss: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Dismissed!')));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
