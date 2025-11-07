import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/providers/tag_filter_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Панель фильтров для пикера тегов
class TagPickerFilters extends ConsumerWidget {
  const TagPickerFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(tagPickerFilterProvider);
    final filterNotifier = ref.read(tagPickerFilterProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Поле поиска
          TextField(
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск тега...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => filterNotifier.updateQuery(''),
                    )
                  : null,
            ),
            onChanged: filterNotifier.updateQuery,
          ),

          const SizedBox(height: 12),

          // Фильтр по типу
          Row(
            children: [
              Text(
                'Тип:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeChip(
                        label: 'Все',
                        isSelected: filter.type == null,
                        onTap: () => filterNotifier.updateType(null),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Логин',
                        isSelected: filter.type == 'login',
                        onTap: () => filterNotifier.updateType('login'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Карта',
                        isSelected: filter.type == 'card',
                        onTap: () => filterNotifier.updateType('card'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Заметка',
                        isSelected: filter.type == 'note',
                        onTap: () => filterNotifier.updateType('note'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Файл',
                        isSelected: filter.type == 'file',
                        onTap: () => filterNotifier.updateType('file'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Чип для выбора типа тега
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
