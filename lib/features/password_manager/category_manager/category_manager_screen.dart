import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'providers/category_filter_provider.dart';
import 'providers/category_pagination_provider.dart';
import 'widgets/category_form_modal.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  List<String> categoryId = [];
  List<String> categoryName = [];
  @override
  void initState() {
    super.initState();
    // Инициализация или загрузка данных, если необходимо
  }

  Widget build(BuildContext context) {
    final currentSortField = ref.watch(
      categoryFilterProvider.select((filter) => filter.sortField),
    );
    final categoryState = ref.watch(categoryListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            title: const Text('Категории'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final searchQuery = ref.read(categoryFilterProvider).query;
                  showSearchDialog(
                    context,
                    initialValue: searchQuery,
                    onSearch: (value) {
                      ref
                          .read(categoryFilterProvider.notifier)
                          .updateQuery(value);
                    },
                  );
                },
                tooltip: 'Поиск',
              ),
              PopupMenuButton<CategoriesSortField>(
                icon: const Icon(Icons.sort),
                tooltip: 'Сортировка',
                onSelected: (sortField) async {
                  if (sortField != currentSortField) {
                    await ref
                        .read(categoryFilterProvider.notifier)
                        .updateSortField(sortField);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: CategoriesSortField.name,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.name)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.name)
                          const SizedBox(width: 8),
                        const Text('По названию'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.type,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.type)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.type)
                          const SizedBox(width: 8),
                        const Text('По типу'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.createdAt,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.createdAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.createdAt)
                          const SizedBox(width: 8),
                        const Text('По дате создания'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CategoriesSortField.modifiedAt,
                    child: Row(
                      children: [
                        if (currentSortField == CategoriesSortField.modifiedAt)
                          const Icon(Icons.check, size: 20),
                        if (currentSortField == CategoriesSortField.modifiedAt)
                          const SizedBox(width: 8),
                        const Text('По дате изменения'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: CategoryPickerField(
              selectedCategoryIds: categoryId,
              isFilter: true,
              filterByType: CategoryType.password,
              selectedCategoryNames: categoryName,
              onCategoriesSelected: (ids, names) {
                setState(() {
                  categoryId = ids;
                  categoryName = names;
                });
              },
            ),
          ),
          categoryState.when(
            data: (state) {
              if (state.items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Категории не найдены')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.items.length && state.hasMore) {
                      // Загружаем следующую страницу при достижении конца
                      Future.microtask(
                        () =>
                            ref.read(categoryListProvider.notifier).loadMore(),
                      );
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (index >= state.items.length) {
                      return null;
                    }
                    return _buildCategoryCard(
                      context,
                      state.items[index],
                      () => ref.read(categoryListProvider.notifier).refresh(),
                    );
                  },
                  childCount: state.hasMore
                      ? state.items.length + 1
                      : state.items.length,
                ),
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
                    const Text('Ошибка загрузки категорий'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(categoryListProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categoryManagerFab',
        onPressed: () {
          showCategoryCreateModal(
            context,
            onSuccess: () => ref.read(categoryListProvider.notifier).refresh(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  static void showSearchDialog(
    BuildContext context, {
    required String initialValue,
    required Function(String) onSearch,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск категорий'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите название...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              onSearch(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryCardDto category,
    VoidCallback onRefresh,
  ) {
    final colorValue = int.tryParse(category.color ?? 'FFFFFF', radix: 16);
    final color = colorValue != null
        ? Color(0xFF000000 | colorValue)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: category.iconId != null
                ? Icon(Icons.folder, color: color)
                : Text(
                    category.name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(category.name),
        subtitle: Text(
          'Тип: ${category.type} • Элементов: ${category.itemsCount}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              showCategoryEditModal(context, category, onSuccess: onRefresh);
            } else if (value == 'delete') {
              await _handleDeleteCategory(context, category, onRefresh);
            }
          },
        ),
        onTap: () {
          showCategoryEditModal(context, category, onSuccess: onRefresh);
        },
      ),
    );
  }

  Future<void> _handleDeleteCategory(
    BuildContext context,
    CategoryCardDto category,
    VoidCallback onRefresh,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          'Вы уверены, что хотите удалить категорию "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final categoryDao = await ref.read(categoryDaoProvider.future);
        await categoryDao.deleteCategory(category.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Категория "${category.name}" успешно удалена'),
            ),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
