import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';

class EntitySliverList<T> extends StatelessWidget {
  final List<T> items;
  final ViewMode viewMode;
  final Widget Function(BuildContext context, T item) listBuilder;
  final Widget Function(BuildContext context, T item)? gridBuilder;
  final void Function(T item)? onTap;
  final void Function(T item)? onLongPress;

  const EntitySliverList({
    super.key,
    required this.items,
    required this.viewMode,
    required this.listBuilder,
    this.gridBuilder,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverFillRemaining(child: Center(child: Text('Список пуст')));
    }

    if (viewMode == ViewMode.list) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return onTap != null || onLongPress != null
              ? GestureDetector(
                  onTap: () => onTap?.call(item),
                  onLongPress: () => onLongPress?.call(item),
                  child: listBuilder(context, item),
                )
              : listBuilder(context, item);
        }, childCount: items.length),
      );
    } else {
      final builder = gridBuilder ?? listBuilder;
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            return onTap != null || onLongPress != null
                ? GestureDetector(
                    onTap: () => onTap?.call(item),
                    onLongPress: () => onLongPress?.call(item),
                    child: builder(context, item),
                  )
                : builder(context, item);
          }, childCount: items.length),
        ),
      );
    }
  }
}
