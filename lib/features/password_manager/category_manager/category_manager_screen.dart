import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
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
  final TextEditingController _searchController = TextEditingController();
  late final PagingController<int, CategoryCardDto> _pagingController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, CategoryCardDto>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: _fetchPage,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  Future<List<CategoryCardDto>> _fetchPage(int pageKey) async {
    final filter = ref.read(categoryFilterProvider);
    return await ref.read(
      categoryPageProvider((filter: filter, pageKey: pageKey)).future,
    );
  }

  void _refresh() {
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final currentSortField = ref.watch(
      categoryFilterProvider.select((filter) => filter.sortField),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            title: _isSearchActive
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Поиск категорий...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(categoryFilterProvider.notifier)
                              .updateQuery('');
                        },
                      ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(categoryFilterProvider.notifier)
                          .updateQuery(value);
                    },
                  )
                : const Text('Категории'),
            actions: [
              if (!_isSearchActive)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = true;
                    });
                  },
                  tooltip: 'Поиск',
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = false;
                      _searchController.clear();
                      ref.read(categoryFilterProvider.notifier).updateQuery('');
                    });
                  },
                  tooltip: 'Закрыть поиск',
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
          PagingListener<int, CategoryCardDto>(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) {
              return PagedSliverList<int, CategoryCardDto>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<CategoryCardDto>(
                  itemBuilder: (context, item, index) {
                    return _buildCategoryCard(item);
                  },
                  firstPageProgressIndicatorBuilder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  noItemsFoundIndicatorBuilder: (context) =>
                      const Center(child: Text('Категории не найдены')),
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ошибка загрузки категорий'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _pagingController.refresh(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categoryManagerFab',
        onPressed: () {
          showCategoryCreateModal(context, onSuccess: _refresh);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryCardDto category) {
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
          onSelected: (value) {
            if (value == 'edit') {
              showCategoryEditModal(context, category, onSuccess: _refresh);
            } else if (value == 'delete') {
              // TODO: Реализовать удаление
            }
          },
        ),
        onTap: () {
          showCategoryEditModal(context, category, onSuccess: _refresh);
        },
      ),
    );
  }
}
