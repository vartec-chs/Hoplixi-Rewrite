import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/universal_modal.dart';

/// Showcase экран для демонстрации компонента UniversalModal
class UniversalModalShowcaseScreen extends StatelessWidget {
  const UniversalModalShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Basic Examples',
          children: [
            _ExampleButton(
              label: 'Simple Modal',
              onPressed: () => _showSimpleModal(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Modal with Title',
              onPressed: () => _showModalWithTitle(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Modal with Actions',
              onPressed: () => _showModalWithActions(context),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Scrollable Content',
          children: [
            _ExampleButton(
              label: 'Long Content',
              onPressed: () => _showScrollableModal(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Form in Modal',
              onPressed: () => _showFormModal(context),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Custom Styling',
          children: [
            _ExampleButton(
              label: 'Custom Colors',
              onPressed: () => _showCustomColorModal(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Custom Shape',
              onPressed: () => _showCustomShapeModal(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Full Screen Modal',
              onPressed: () => _showFullScreenModal(context),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Advanced Examples',
          children: [
            _ExampleButton(
              label: 'Confirmation Dialog',
              onPressed: () => _showConfirmationDialog(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Nested Modals',
              onPressed: () => _showNestedModal(context),
            ),
            const SizedBox(height: 12),
            _ExampleButton(
              label: 'Modal with Return Value',
              onPressed: () => _showModalWithReturnValue(context),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // Basic Examples
  // ============================================================================

  void _showSimpleModal(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => const UniversalModalContent(
        child: Text(
          'Это простой модал с коротким текстом. '
          'На мобильных устройствах отобразится как bottom sheet, '
          'на десктопе — как dialog.',
        ),
        shrinkWrap: true,
      ),
    );
  }

  void _showModalWithTitle(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => const UniversalModalContent(
        title: Text('Модал с заголовком'),
        shrinkWrap: true,
        child: Text(
          'Заголовок автоматически стилизуется в соответствии с темой приложения. '
          'Контент выравнивается по центру и имеет адаптивные отступы.',
        ),
      ),
    );
  }

  void _showModalWithActions(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => UniversalModalContent(
        title: const Text('Подтверждение действия'),
        shrinkWrap: true,
        child: const Text('Вы уверены, что хотите выполнить это действие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Действие выполнено')),
              );
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Scrollable Content
  // ============================================================================

  void _showScrollableModal(BuildContext context) {
    UniversalModal.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => UniversalModalContent(
        title: const Text('Длинный контент'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Это содержимое будет прокручиваться, если оно больше размера экрана. '
              'На мобильных устройствах можно перетаскивать bottom sheet для его закрытия.',
            ),
            const SizedBox(height: 16),
            ...List.generate(
              25,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Элемент ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Это элемент списка номер ${index + 1}. '
                          'Вы можете добавить любой контент внутрь модала.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showFormModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String? name;

    UniversalModal.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => UniversalModalContent(
        title: const Text('Форма обратной связи'),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  hintText: 'Введите ваше имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Поле обязательно';
                  return null;
                },
                onSaved: (value) => name = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@mail.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Поле обязательно';
                  if (!value!.contains('@')) return 'Неверный email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Сообщение',
                  hintText: 'Ваше сообщение',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Поле обязательно';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Спасибо, $name! Мы получили ваше письмо'),
                  ),
                );
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Custom Styling
  // ============================================================================

  void _showCustomColorModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    UniversalModal.show(
      context: context,
      backgroundColor: colorScheme.primaryContainer,
      builder: (context) => UniversalModalContent(
        title: Text(
          'Модал с кастомными цветами',
          style: TextStyle(color: colorScheme.onPrimaryContainer),
        ),
        shrinkWrap: true,
        child: Text(
          'Фон модала имеет кастомный цвет. '
          'Вы можете передать любые параметры для кастомизации внешнего вида.',
          style: TextStyle(color: colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }

  void _showCustomShapeModal(BuildContext context) {
    UniversalModal.show(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      builder: (context) => const UniversalModalContent(
        title: Text('Кастомная форма'),
        shrinkWrap: true,
        child: Text(
          'Модал с кастомной границей и большим border radius. '
          'Вы можете передать любую ShapeBorder.',
        ),
      ),
    );
  }

  void _showFullScreenModal(BuildContext context) {
    UniversalModal.show(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints.expand(),
      builder: (context) => UniversalModalContent(
        title: const Text('Полноэкранный модал'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fullscreen,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Этот модал занимает весь экран',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'На десктопе максимальный размер ограничен параметром constraints',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Advanced Examples
  // ============================================================================

  void _showConfirmationDialog(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => UniversalModalContent(
        title: const Text('Внимание'),
        shrinkWrap: true,
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Вы собираетесь удалить этот элемент. '
              'Это действие невозможно отменить.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Элемент удален')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showNestedModal(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => UniversalModalContent(
        title: const Text('Основной модал'),
        shrinkWrap: true,
        child: const Text('Нажмите кнопку ниже, чтобы открыть вложенный модал'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              _showNestedModalInner(context);
            },
            child: const Text('Открыть вложенный'),
          ),
        ],
      ),
    );
  }

  void _showNestedModalInner(BuildContext context) {
    UniversalModal.show(
      context: context,
      builder: (context) => UniversalModalContent(
        title: const Text('Вложенный модал'),
        shrinkWrap: true,
        child: const Text(
          'Это вложенный модал, открытый поверх основного. '
          'Вы можете открывать модалы один внутри другого.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _showModalWithReturnValue(BuildContext context) async {
    final result = await UniversalModal.show<String>(
      context: context,
      builder: (context) => UniversalModalContent(
        title: const Text('Выберите опцию'),
        shrinkWrap: true,
        child: const Text(
          'Модал может возвращать значение при закрытии. '
          'Нажмите одну из кнопок ниже.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('Отмена'),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('Выбрано'),
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Результат: $result')));
      }
    }
  }

  // ============================================================================
  // Helpers
  // ============================================================================

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

/// Вспомогательный виджет кнопки для примеров
class _ExampleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ExampleButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
