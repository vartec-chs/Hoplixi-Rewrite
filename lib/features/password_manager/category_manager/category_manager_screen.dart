import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'providers/category_filter_provider.dart';
import 'providers/category_pagination_provider.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() =>
      _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final PagingController<int, CategoryCardDto> _pagingController;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Перезагружаем данные при изменении фильтра
    ref.listen(categoryFilterProvider, (previous, next) {
      _pagingController.refresh();
    });
  }

  void _showCreateCategoryModal() {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [_buildCreateCategoryPage(context)],
    );
  }

  WoltModalSheetPage _buildCreateCategoryPage(BuildContext modalContext) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String? description;
    String? color;

    return WoltModalSheetPage(
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      topBarTitle: Text(
        'Создать категорию',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      isTopBarLayerAlwaysVisible: true,
      leadingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => description = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Цвет (HEX, например FFFFFF)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => color = value,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    // TODO: Создать категорию через DAO
                    Navigator.of(modalContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Категория "$name" создана')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Создать'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск категорий...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(categoryFilterProvider.notifier)
                                  .updateSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    ref
                        .read(categoryFilterProvider.notifier)
                        .updateSearchQuery(value);
                  },
                ),
              ),
            ),
            actions: [
              PopupMenuButton<CategoriesSortField>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  ref
                      .read(categoryFilterProvider.notifier)
                      .updateSortField(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: CategoriesSortField.name,
                    child: Text('По названию'),
                  ),
                  const PopupMenuItem(
                    value: CategoriesSortField.type,
                    child: Text('По типу'),
                  ),
                  const PopupMenuItem(
                    value: CategoriesSortField.createdAt,
                    child: Text('По дате создания'),
                  ),
                  const PopupMenuItem(
                    value: CategoriesSortField.modifiedAt,
                    child: Text('По дате изменения'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showCreateCategoryModal,
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
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  newPageProgressIndicatorBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  noItemsFoundIndicatorBuilder: (context) =>
                      const SliverFillRemaining(
                        child: Center(child: Text('Категории не найдены')),
                      ),
                  firstPageErrorIndicatorBuilder: (context) =>
                      SliverFillRemaining(
                        child: Center(
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
                ),
              );
            },
          ),
        ],
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
            // TODO: Реализовать действия
          },
        ),
        onTap: () {
          // TODO: Открыть детали категории
        },
      ),
    );
  }
}
