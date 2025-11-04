import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import '../provider/icon_filter_provider.dart';

/// SliverAppBar для экрана управления иконками
class IconManagerAppBar extends ConsumerStatefulWidget {
  const IconManagerAppBar({super.key});

  @override
  ConsumerState<IconManagerAppBar> createState() => _IconManagerAppBarState();
}

class _IconManagerAppBarState extends ConsumerState<IconManagerAppBar> {
  late final TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: primaryInputDecoration(
                context,
                hintText: 'Поиск иконок...',

                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(iconFilterProvider.notifier).updateQuery('');
                  },
                ),
              ),
              onChanged: (value) {
                ref.read(iconFilterProvider.notifier).updateQuery(value);
              },
            )
          : const Text('Иконки'),
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
                ref.read(iconFilterProvider.notifier).updateQuery('');
              });
            },
            tooltip: 'Закрыть поиск',
          ),
        Consumer(
          builder: (context, ref, child) {
            final currentSortField = ref.watch(
              iconFilterProvider.select((filter) => filter.sortField),
            );

            return PopupMenuButton<IconsSortField>(
              icon: const Icon(Icons.sort),
              tooltip: 'Сортировка',
              onSelected: (sortField) {
                // Избегаем ненужного обновления если значение не изменилось
                if (sortField != currentSortField) {
                  ref
                      .read(iconFilterProvider.notifier)
                      .updateSortField(sortField);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: IconsSortField.name,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.name)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.name)
                        const SizedBox(width: 8),
                      const Text('По названию'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.type,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.type)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.type)
                        const SizedBox(width: 8),
                      const Text('По типу'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.createdAt,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.createdAt)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.createdAt)
                        const SizedBox(width: 8),
                      const Text('По дате создания'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.modifiedAt,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.modifiedAt)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.modifiedAt)
                        const SizedBox(width: 8),
                      const Text('По дате изменения'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            _showFilterDialog(context);
          },
          tooltip: 'Фильтры',
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    final filter = ref.read(iconFilterProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фильтр по типу
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Тип иконки',
                  hintText: 'Например: svg, png',
                ),
                controller: TextEditingController(text: filter.type ?? ''),
                onChanged: (value) {
                  ref
                      .read(iconFilterProvider.notifier)
                      .updateType(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 16),
              // Здесь можно добавить больше фильтров (даты и т.д.)
              Text(
                'Фильтры по датам можно добавить здесь',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(iconFilterProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
