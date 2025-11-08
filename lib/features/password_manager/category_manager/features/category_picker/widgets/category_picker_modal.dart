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
      forceMaxHeight: true,
      resizeToAvoidBottomInset: false,

      topBarTitle: const Text('Выберите категорию'),
      isTopBarLayerAlwaysVisible: true,

      mainContentSliversBuilder: (context) => [
        // Фильтры
        SliverToBoxAdapter(child: const CategoryPickerFilters()),

        // Список категорий
        _CategoryListView(
          currentCategoryId: currentCategoryId,
          onCategorySelected: onCategorySelected,
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

/// Список категорий с анимацией (одиночный выбор)
class _CategoryListView extends ConsumerStatefulWidget {
  const _CategoryListView({
    required this.currentCategoryId,
    required this.onCategorySelected,
  });

  final String? currentCategoryId;
  final Function(String categoryId, String categoryName) onCategorySelected;

  @override
  ConsumerState<_CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<_CategoryListView> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  List<dynamic> _items = [];
  bool _showLoadingIndicator = false;

  @override
  void initState() {
    super.initState();
    // Запускаем таймер для индикатора загрузки
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _items.isEmpty) {
        setState(() => _showLoadingIndicator = true);
      }
    });
  }

  void _updateItems(List<dynamic> newItems) {
    if (!mounted) return;

    final oldLength = _items.length;
    final newLength = newItems.length;

    // Если список пустой, просто заменяем
    if (oldLength == 0) {
      setState(() {
        _items = List.from(newItems);
        _showLoadingIndicator = false;
      });
      // Анимируем добавление всех элементов
      for (int i = 0; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + i * 20),
        );
      }
      return;
    }

    // Удаляем лишние элементы
    if (newLength < oldLength) {
      for (int i = oldLength - 1; i >= newLength; i--) {
        final item = _items[i];
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(item, animation, false),
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    // Добавляем новые элементы
    if (newLength > oldLength) {
      for (int i = oldLength; i < newLength; i++) {
        _listKey.currentState?.insertItem(
          i,
          duration: Duration(milliseconds: 200 + (i - oldLength) * 20),
        );
      }
    }

    setState(() {
      _items = List.from(newItems);
      _showLoadingIndicator = false;
    });
  }

  Widget _buildAnimatedItem(
    dynamic category,
    Animation<double> animation,
    bool isSelected,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: CategoryPickerItem(
          category: category,
          isSelected: isSelected,
          onTap: () {
            widget.onCategorySelected(category.id, category.name);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoryPickerListProvider);

    return categoriesState.when(
      data: (state) {
        // Обновляем список при получении новых данных
        if (state.items.length != _items.length ||
            (state.items.isNotEmpty &&
                _items.isNotEmpty &&
                state.items.first.id != _items.first.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateItems(state.items);
          });
        }

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

        return SliverAnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            if (index >= _items.length) {
              return const SizedBox.shrink();
            }

            final category = _items[index];
            final isSelected = category.id == widget.currentCategoryId;

            return _buildAnimatedItem(category, animation, isSelected);
          },
        );
      },
      loading: () {
        // Показываем индикатор только после задержки
        return SliverFillRemaining(
          child: Center(
            child: _showLoadingIndicator
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
          ),
        );
      },
      error: (error, stack) {
        setState(() => _showLoadingIndicator = false);
        return SliverFillRemaining(
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
        );
      },
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
  bool _showLoadingIndicator = false;
  List<dynamic>? _cachedItems; // Кешированные данные

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
        // Фильтры (с учетом filterByType и счетчиком)
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
              selectedCount: _selectedCategoryIds.length,
            );
          },
        ),

        // Список категорий
        Consumer(
          builder: (context, ref, child) {
            final categoriesState = ref.watch(categoryPickerListProvider);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: categoriesState.when(
                data: (state) {
                  // Сбрасываем индикатор загрузки при получении данных
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _showLoadingIndicator) {
                      setState(() => _showLoadingIndicator = false);
                    }
                  });

                  // Кешируем данные
                  if (state.items.isNotEmpty) {
                    _cachedItems = state.items;
                  }

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
                                        .read(
                                          categoryPickerListProvider.notifier,
                                        )
                                        .loadMore();
                                  },
                                  child: const Text('Загрузить еще'),
                                ),
                        ),
                    ],
                  );
                },
                loading: () {
                  // Показываем индикатор загрузки только после 300ms
                  if (!_showLoadingIndicator) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() => _showLoadingIndicator = true);
                      }
                    });
                  }

                  // Если есть кешированные данные, показываем их
                  if (_cachedItems != null && _cachedItems!.isNotEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(_cachedItems!.length, (index) {
                          final category = _cachedItems![index];
                          final isSelected = _selectedCategoryIds.contains(
                            category.id,
                          );

                          return CategoryPickerItem(
                            category: category,
                            isSelected: isSelected,
                            onTap: () => _toggleCategory(
                              category.id,
                              category.name,
                              _cachedItems!,
                            ),
                          );
                        }),
                        // Показываем индикатор загрузки внизу списка
                        if (_showLoadingIndicator)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    );
                  }

                  // Если кеша нет, показываем центральный индикатор
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: _showLoadingIndicator
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                },
                error: (error, stack) {
                  // Сбрасываем индикатор при ошибке
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _showLoadingIndicator) {
                      setState(() => _showLoadingIndicator = false);
                    }
                  });

                  return SizedBox(
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
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
