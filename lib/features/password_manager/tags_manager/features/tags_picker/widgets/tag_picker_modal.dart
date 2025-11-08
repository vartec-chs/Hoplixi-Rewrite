import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/providers/tag_picker_provider.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/widgets/tag_picker_filters.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/widgets/tag_picker_item.dart';

/// Модальное окно выбора тегов
class TagPickerModal {
  /// Показать модальное окно выбора тегов (множественный выбор)
  static Future<void> show({
    required BuildContext context,
    required Function(List<String> tagIds, List<String> tagNames)
    onTagsSelected,
    List<String>? currentTagIds,
    int? maxTagPicks,
    String? filterByType,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onTagsSelected: onTagsSelected,
          currentTagIds: currentTagIds ?? [],
          maxTagPicks: maxTagPicks,
          isSingleMode: false,
          filterByType: filterByType,
        ),
      ],
    );
  }

  /// Показать модальное окно выбора тега (одиночный выбор)
  static Future<void> showSingle({
    required BuildContext context,
    required Function(String? tagId, String? tagName) onTagSelected,
    String? currentTagId,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onTagSelected: onTagSelected,
          currentTagIds: currentTagId != null ? [currentTagId] : [],
          maxTagPicks: 1,
          isSingleMode: true,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage _buildPickerPage(
    BuildContext context, {
    Function(List<String> tagIds, List<String> tagNames)? onTagsSelected,
    Function(String? tagId, String? tagName)? onTagSelected,
    required List<String> currentTagIds,
    int? maxTagPicks,
    required bool isSingleMode,
    String? filterByType,
  }) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      forceMaxHeight: true,
      topBarTitle: Text(
        isSingleMode
            ? 'Выберите тег'
            : (maxTagPicks != null && maxTagPicks > 0
                  ? 'Выберите теги (макс. $maxTagPicks)'
                  : 'Выберите теги'),
      ),
      isTopBarLayerAlwaysVisible: true,
      mainContentSliversBuilder: (context) => [
        // Контент с состоянием
        SliverToBoxAdapter(
          child: _TagPickerContent(
            onTagsSelected: onTagsSelected,
            onTagSelected: onTagSelected,
            initialTagIds: currentTagIds,
            maxTagPicks: maxTagPicks,
            isSingleMode: isSingleMode,
            filterByType: filterByType,
          ),
        ),
      ],
    );
  }
}

/// Контент модального окна с состоянием выбранных тегов
class _TagPickerContent extends StatefulWidget {
  const _TagPickerContent({
    this.onTagsSelected,
    this.onTagSelected,
    required this.initialTagIds,
    this.maxTagPicks,
    required this.isSingleMode,
    this.filterByType,
  });

  final Function(List<String> tagIds, List<String> tagNames)? onTagsSelected;
  final Function(String? tagId, String? tagName)? onTagSelected;
  final List<String> initialTagIds;
  final int? maxTagPicks;
  final bool isSingleMode;
  final String? filterByType;

  @override
  State<_TagPickerContent> createState() => _TagPickerContentState();
}

class _TagPickerContentState extends State<_TagPickerContent> {
  late List<String> _selectedTagIds;
  bool _showLoadingIndicator = false;
  List<dynamic>? _cachedItems; // Кешированные данные

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List<String>.from(widget.initialTagIds);
  }

  void _toggleTag(String tagId, String tagName, List<dynamic> allTags) {
    if (widget.isSingleMode) {
      // Режим одиночного выбора
      setState(() {
        if (_selectedTagIds.contains(tagId)) {
          // Снимаем выбор
          _selectedTagIds.clear();
          widget.onTagSelected?.call(null, null);
        } else {
          // Выбираем новый тег
          _selectedTagIds = [tagId];
          widget.onTagSelected?.call(tagId, tagName);
        }
      });
    } else {
      // Режим множественного выбора
      setState(() {
        if (_selectedTagIds.contains(tagId)) {
          // Убираем тег из выбранных
          _selectedTagIds.remove(tagId);
        } else {
          // Проверяем лимит
          if (widget.maxTagPicks != null &&
              _selectedTagIds.length >= widget.maxTagPicks!) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Можно выбрать максимум ${widget.maxTagPicks} тегов',
                ),
              ),
            );
            return;
          }
          _selectedTagIds.add(tagId);
        }
      });

      // Собираем имена для выбранных тегов
      final selectedTagNames = <String>[];
      for (final tagId in _selectedTagIds) {
        try {
          final selectedTag = allTags.firstWhere((t) => t.id == tagId);
          selectedTagNames.add(selectedTag.name as String);
        } catch (e) {
          // Тег не найден в списке, пропускаем
          continue;
        }
      }

      widget.onTagsSelected?.call(_selectedTagIds, selectedTagNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Фильтры
        TagPickerFilters(
          filterByType: widget.filterByType,
          selectedCount: _selectedTagIds.length,
          maxCount: widget.maxTagPicks,
        ),

        // Список тегов
        Consumer(
          builder: (context, ref, child) {
            final tagsState = ref.watch(tagPickerListProvider);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: tagsState.when(
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
                              Icons.label_outline,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Теги не найдены',
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
                        final tag = state.items[index];
                        final isSelected = _selectedTagIds.contains(tag.id);

                        return TagPickerItem(
                          tag: tag,
                          isSelected: isSelected,
                          onTap: () =>
                              _toggleTag(tag.id, tag.name, state.items),
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
                                        .read(tagPickerListProvider.notifier)
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
                          final tag = _cachedItems![index];
                          final isSelected = _selectedTagIds.contains(tag.id);

                          return TagPickerItem(
                            tag: tag,
                            isSelected: isSelected,
                            onTap: () =>
                                _toggleTag(tag.id, tag.name, _cachedItems!),
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
                            'Ошибка загрузки тегов',
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
