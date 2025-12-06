import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/features/logs_viewer/providers/logs_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет для фильтрации и поиска логов
class LogsFilterBar extends ConsumerWidget {
  const LogsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelFilter = ref.watch(logLevelFilterProvider);
    final tagFilter = ref.watch(logTagFilterProvider);
    final searchQuery = ref.watch(logSearchQueryProvider);
    final availableTags = ref.watch(availableTagsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поиск
          TextField(
            onChanged: (value) {
              ref.read(logSearchQueryProvider.notifier).setQuery(value);
            },
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск по сообщению, тегу или ошибке...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(logSearchQueryProvider.notifier).setQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Фильтры
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Фильтр по уровню
              PopupMenuButton<LogLevel?>(
                tooltip: 'Фильтр по уровню',
                child: FilterChip(
                  label: Text(
                    levelFilter == null
                        ? 'Уровень'
                        : 'Уровень: ${levelFilter.name}',
                  ),
                  selected: levelFilter != null,
                  onSelected: (_) {},
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: null,
                    child: const Text('Все уровни'),
                    onTap: () {
                      ref.read(logLevelFilterProvider.notifier).setLevel(null);
                    },
                  ),
                  ...LogLevel.values.map(
                    (level) => PopupMenuItem(
                      value: level,
                      child: Text(level.name),
                      onTap: () {
                        ref
                            .read(logLevelFilterProvider.notifier)
                            .setLevel(level);
                      },
                    ),
                  ),
                ],
              ),
              // Фильтр по тегу
              availableTags.when(
                loading: () => const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stackTrace) => const SizedBox(),
                data: (tags) {
                  if (tags.isEmpty) {
                    return const SizedBox();
                  }

                  return PopupMenuButton<String?>(
                    tooltip: 'Фильтр по тегу',
                    child: FilterChip(
                      label: Text(
                        tagFilter == null ? 'Теги' : 'Теги: $tagFilter',
                      ),
                      selected: tagFilter != null,
                      onSelected: (_) {},
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: null,
                        child: const Text('Все теги'),
                        onTap: () {
                          ref.read(logTagFilterProvider.notifier).setTag(null);
                        },
                      ),
                      ...tags.map(
                        (tag) => PopupMenuItem(
                          value: tag,
                          child: Text(tag),
                          onTap: () {
                            ref.read(logTagFilterProvider.notifier).setTag(tag);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Кнопка очистки фильтров
              if (levelFilter != null ||
                  tagFilter != null ||
                  searchQuery.isNotEmpty)
                FilterChip(
                  label: const Text('Очистить'),
                  onSelected: (_) {
                    ref.read(logLevelFilterProvider.notifier).setLevel(null);
                    ref.read(logTagFilterProvider.notifier).setTag(null);
                    ref.read(logSearchQueryProvider.notifier).setQuery('');
                  },
                  backgroundColor: theme.colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
