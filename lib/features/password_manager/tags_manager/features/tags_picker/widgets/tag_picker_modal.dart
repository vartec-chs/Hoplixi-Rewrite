import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/providers/tag_picker_provider.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/widgets/tag_picker_filters.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/widgets/tag_picker_item.dart';

/// Модальное окно выбора тегов
class TagPickerModal {
  /// Показать модальное окно выбора тегов
  static Future<void> show({
    required BuildContext context,
    required Function(List<String> tagIds, List<String> tagNames)
    onTagsSelected,
    List<String>? currentTagIds,
    int? maxTagPicks,
  }) {
    return WoltModalSheet.show(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (context) => [
        _buildPickerPage(
          context,
          onTagsSelected,
          currentTagIds ?? [],
          maxTagPicks,
        ),
      ],
    );
  }

  static SliverWoltModalSheetPage _buildPickerPage(
    BuildContext context,
    Function(List<String> tagIds, List<String> tagNames) onTagsSelected,
    List<String> currentTagIds,
    int? maxTagPicks,
  ) {
    return SliverWoltModalSheetPage(
      heroImage: null,
      hasTopBarLayer: true,
      topBarTitle: Text(
        maxTagPicks != null && maxTagPicks > 0
            ? 'Выберите теги (макс. $maxTagPicks)'
            : 'Выберите теги',
      ),
      isTopBarLayerAlwaysVisible: true,
      mainContentSliversBuilder: (context) => [
        // Контент с состоянием
        SliverToBoxAdapter(
          child: _TagPickerContent(
            onTagsSelected: onTagsSelected,
            initialTagIds: currentTagIds,
            maxTagPicks: maxTagPicks,
          ),
        ),
      ],
    );
  }
}

/// Контент модального окна с состоянием выбранных тегов
class _TagPickerContent extends StatefulWidget {
  const _TagPickerContent({
    required this.onTagsSelected,
    required this.initialTagIds,
    this.maxTagPicks,
  });

  final Function(List<String> tagIds, List<String> tagNames) onTagsSelected;
  final List<String> initialTagIds;
  final int? maxTagPicks;

  @override
  State<_TagPickerContent> createState() => _TagPickerContentState();
}

class _TagPickerContentState extends State<_TagPickerContent> {
  late List<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List<String>.from(widget.initialTagIds);
  }

  void _toggleTag(String tagId, String tagName, List<dynamic> allTags) {
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

    widget.onTagsSelected(_selectedTagIds, selectedTagNames);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Счетчик выбранных тегов
        if (_selectedTagIds.isNotEmpty)
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.maxTagPicks != null
                        ? '${_selectedTagIds.length} / ${widget.maxTagPicks}'
                        : '${_selectedTagIds.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Фильтры
        const TagPickerFilters(),

        // Список тегов
        Consumer(
          builder: (context, ref, child) {
            final tagsState = ref.watch(tagPickerListProvider);

            return tagsState.when(
              data: (state) {
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
                        onTap: () => _toggleTag(tag.id, tag.name, state.items),
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
              ),
            );
          },
        ),
      ],
    );
  }
}
