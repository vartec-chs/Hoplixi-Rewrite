import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_filter_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Панель фильтров для пикера категорий
class CategoryPickerFilters extends ConsumerWidget {
  const CategoryPickerFilters({super.key, this.hideTypeFilter = false});

  /// Скрыть фильтр по типу (используется когда тип уже задан извне)
  final bool hideTypeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(categoryPickerFilterProvider);
    final filterNotifier = ref.read(categoryPickerFilterProvider.notifier);
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
              hintText: 'Поиск категории...',
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

          // Фильтр по типу (скрываем если hideTypeFilter = true)
          if (!hideTypeFilter) ...[
            const SizedBox(height: 12),
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
                          label: 'Пароли',
                          isSelected:
                              filter.type == CategoryType.password.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.password.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'Банковские карты',
                          isSelected:
                              filter.type == CategoryType.bankCard.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.bankCard.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'Заметки',
                          isSelected: filter.type == CategoryType.notes.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.notes.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'Файлы',
                          isSelected: filter.type == CategoryType.files.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.files.value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: 'Mixed',
                          isSelected: filter.type == CategoryType.mixed.value,
                          onTap: () => filterNotifier.updateType(
                            CategoryType.mixed.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Чип для выбора типа категории
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
