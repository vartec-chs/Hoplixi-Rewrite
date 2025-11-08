import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_picker_provider.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_filter_provider.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_filters.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_item.dart';

/// Модальное окно выбора категории
class CategoryPickerModal {
  /// Показать модальное окно выбора категории (одиночный выбор)
  static Future<void> show({
    required BuildContext context,
    required Function(String categoryId, String categoryName)
    onCategorySelected,
    String? currentCategoryId,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(context, onCategorySelected, currentCategoryId),
      ],
    );
  }

  /// Показать модальное окно выбора категорий (множественный выбор для фильтра)
  static Future<void> showMultiple({
    required BuildContext context,
    required Function(List<String> categoryIds, List<String> categoryNames)
    onCategoriesSelected,
    List<String>? currentCategoryIds,
    String? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildMultiplePickerPage(
          context,
          onCategoriesSelected,
          currentCategoryIds ?? [],
          filterByType,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage _buildPickerPage(
    BuildContext context,
    Function(String categoryId, String categoryName) onCategorySelected,
    String? currentCategoryId,
  ) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      topBarTitle: const Text('Выберите категорию'),
      isTopBarLayerAlwaysVisible: true,

      mainContentSliversBuilder: (context) => [
        // Фильтры
        SliverToBoxAdapter(child: const CategoryPickerFilters()),

        // Список категорий
        Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(categoryPickerListProvider);

            return categoriesState.when(
              data: (state) {
                if (state.items.isEmpty && !state.isLoading) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Категории не найдены',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Проверка на подгрузку следующей страницы
                    if (index >= state.items.length) {
                      if (state.hasMore && !state.isLoading) {
                        // Загружаем следующую страницу
                        Future.microtask(() {
                          ref
                              .read(categoryPickerListProvider.notifier)
                              .loadMore();
                        });
                      }
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final category = state.items[index];
                    final isSelected = category.id == currentCategoryId;

                    return CategoryPickerItem(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        onCategorySelected(category.id, category.name);
                        Navigator.of(context).pop();
                      },
                    );
                  }, childCount: state.items.length + (state.hasMore ? 1 : 0)),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки категорий',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Построить страницу с множественным выбором категорий
  static SliverWoltModalSheetPage _buildMultiplePickerPage(
    BuildContext context,
    Function(List<String> categoryIds, List<String> categoryNames)
    onCategoriesSelected,
    List<String> currentCategoryIds,
    String? filterByType,
  ) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      topBarTitle: const Text('Выберите категории'),
      isTopBarLayerAlwaysVisible: true,
      mainContentSliversBuilder: (context) => [
        // Контент с состоянием
        SliverToBoxAdapter(
          child: _MultipleCategoryPickerContent(
            onCategoriesSelected: onCategoriesSelected,
            initialCategoryIds: currentCategoryIds,
            filterByType: filterByType,
          ),
        ),
      ],
    );
  }
}

/// Контент модального окна с состоянием выбранных категорий (множественный выбор)
class _MultipleCategoryPickerContent extends StatefulWidget {
  const _MultipleCategoryPickerContent({
    required this.onCategoriesSelected,
    required this.initialCategoryIds,
    this.filterByType,
  });

  final Function(List<String> categoryIds, List<String> categoryNames)
  onCategoriesSelected;
  final List<String> initialCategoryIds;
  final String? filterByType;

  @override
  State<_MultipleCategoryPickerContent> createState() =>
      _MultipleCategoryPickerContentState();
}

class _MultipleCategoryPickerContentState
    extends State<_MultipleCategoryPickerContent> {
  late List<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List<String>.from(widget.initialCategoryIds);
  }

  void _toggleCategory(
    String categoryId,
    String categoryName,
    List<dynamic> allCategories,
  ) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        // Убираем категорию из выбранных
        _selectedCategoryIds.remove(categoryId);
      } else {
        // Добавляем категорию
        _selectedCategoryIds.add(categoryId);
      }
    });

    // Собираем имена для выбранных категорий
    final selectedCategoryNames = <String>[];
    for (final categoryId in _selectedCategoryIds) {
      try {
        final selectedCategory = allCategories.firstWhere(
          (c) => c.id == categoryId,
        );
        selectedCategoryNames.add(selectedCategory.name as String);
      } catch (e) {
        // Категория не найдена в списке, пропускаем
        continue;
      }
    }

    widget.onCategoriesSelected(_selectedCategoryIds, selectedCategoryNames);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Счетчик выбранных категорий
        if (_selectedCategoryIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedCategoryIds.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Фильтры (с учетом filterByType)
        Consumer(
          builder: (context, ref, child) {
            // Если задан тип для фильтрации, применяем его
            if (widget.filterByType != null) {
              Future.microtask(() {
                ref
                    .read(categoryPickerFilterProvider.notifier)
                    .updateType(widget.filterByType);
              });
            }
            return CategoryPickerFilters(
              hideTypeFilter: widget.filterByType != null,
            );
          },
        ),

        // Список категорий
        Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(categoryPickerListProvider);

            return categoriesState.when(
              data: (state) {
                if (state.items.isEmpty && !state.isLoading) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Категории не найдены',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(state.items.length, (index) {
                      final category = state.items[index];
                      final isSelected = _selectedCategoryIds.contains(
                        category.id,
                      );

                      return CategoryPickerItem(
                        category: category,
                        isSelected: isSelected,
                        onTap: () => _toggleCategory(
                          category.id,
                          category.name,
                          state.items,
                        ),
                      );
                    }),
                    if (state.hasMore)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : TextButton(
                                onPressed: () {
                                  ref
                                      .read(categoryPickerListProvider.notifier)
                                      .loadMore();
                                },
                                child: const Text('Загрузить еще'),
                              ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки категорий',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
