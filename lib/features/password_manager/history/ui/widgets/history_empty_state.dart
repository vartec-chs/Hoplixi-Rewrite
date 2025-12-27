import 'package:flutter/material.dart';

/// Пустое состояние для экрана истории
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key, this.isSearchActive = false});

  final bool isSearchActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSearchActive ? Icons.search_off : Icons.history_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Заголовок
            Text(
              isSearchActive ? 'Ничего не найдено' : 'История пуста',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Описание
            Text(
              isSearchActive
                  ? 'Попробуйте изменить поисковый запрос'
                  : 'Здесь будут отображаться изменения записи',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
