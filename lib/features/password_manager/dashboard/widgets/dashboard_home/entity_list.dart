import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';

class EntitySliverList<T> extends StatelessWidget {
  final List<T> items;
  final ViewMode viewMode;
  final Widget Function(BuildContext context, T item) listBuilder;
  final Widget Function(BuildContext context, T item)? gridBuilder;
  final void Function(T item)? onTap;
  final void Function(T item)? onLongPress;
  final Duration animationDuration;
  final Curve animationCurve;

  const EntitySliverList({
    super.key,
    required this.items,
    required this.viewMode,
    required this.listBuilder,
    this.gridBuilder,
    this.onTap,
    this.onLongPress,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Список пуст')),
      );
    }

    if (viewMode == ViewMode.list) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return _AnimatedListItem(
            index: index,
            duration: animationDuration,
            curve: animationCurve,
            child: onTap != null || onLongPress != null
                ? GestureDetector(
                    onTap: () => onTap?.call(item),
                    onLongPress: () => onLongPress?.call(item),
                    child: listBuilder(context, item),
                  )
                : listBuilder(context, item),
          );
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
            return _AnimatedListItem(
              index: index,
              duration: animationDuration,
              curve: animationCurve,
              child: onTap != null || onLongPress != null
                  ? GestureDetector(
                      onTap: () => onTap?.call(item),
                      onLongPress: () => onLongPress?.call(item),
                      child: builder(context, item),
                    )
                  : builder(context, item),
            );
          }, childCount: items.length),
        ),
      );
    }
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const _AnimatedListItem({
    required this.index,
    required this.child,
    required this.duration,
    required this.curve,
  });

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Задержка анимации в зависимости от индекса элемента
    final delay = Duration(milliseconds: widget.index * 30);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
