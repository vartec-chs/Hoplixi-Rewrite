import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/providers/category_picker_provider.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_filters.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_item.dart';

/// Модальное окно выбора категории
class CategoryPickerModal {
  /// Показать модальное окно выбора категории
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
}
