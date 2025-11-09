import 'package:flutter/material.dart';

/// Направление раскрытия FAB кнопок
enum FABExpandDirection {
  /// Вертикально вверх (в столбик)
  up,

  /// Горизонтально вправо (в линию)
  right,
}

/// Callback для уведомления об изменении состояния открытия/закрытия
typedef FABStateChangeCallback = void Function(bool isOpen);

@immutable
class ExpandableFAB extends StatefulWidget {
  const ExpandableFAB({
    super.key,
    this.initialOpen,
    this.distance = 112,
    this.iconData,
    this.expandDirection = FABExpandDirection.up,
    this.onStateChanged,
    this.showActionsInOverlay = false,

    this.importOtpCodes,
    this.migratePasswords,

    required this.onCreateEntity,
    required this.entityName,

    required this.onCreateCategory,
    required this.onCreateTag,
    required this.onIconCreate,
  });

  final bool? initialOpen;
  final double distance;
  final String entityName;
  final IconData? iconData;
  final FABExpandDirection expandDirection;
  final FABStateChangeCallback? onStateChanged;
  final bool showActionsInOverlay;
  final VoidCallback? importOtpCodes;
  final VoidCallback? migratePasswords;
  final VoidCallback onCreateEntity;
  final VoidCallback onCreateCategory;
  final VoidCallback onCreateTag;
  final VoidCallback onIconCreate;

  @override
  State<ExpandableFAB> createState() => ExpandableFABState();
}

class ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  Animation<double> get expandAnimation => _expandAnimation;
  bool get isOpen => _open;

  /// Публичный метод для переключения состояния FAB
  void toggle() {
    _toggle();
  }

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onStateChanged?.call(_open);
    });
  }

  void _executeAction(VoidCallback action) {
    _toggle(); // Закрываем FAB
    action(); // Выполняем действие
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.showActionsInOverlay) _buildTapToCloseFab(),
          // Показываем кнопки здесь только если не используем overlay
          if (!widget.showActionsInOverlay) ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          color: Theme.of(context).colorScheme.secondary,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    return _buildActionsList()
        .asMap()
        .entries
        .map(
          (entry) => _ExpandingActionButton(
            index: entry.key,
            spacing: 60,
            progress: _expandAnimation,
            direction: widget.expandDirection,
            child: entry.value,
          ),
        )
        .toList();
  }

  List<ActionButton> _buildActionsList() {
    return [
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateTag),
        icon: const Icon(Icons.local_offer),
        label: 'Создать тег',
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateCategory),
        icon: const Icon(Icons.folder),
        label: 'Создать категорию',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      ActionButton(
        onPressed: () => _executeAction(widget.onIconCreate),
        icon: const Icon(Icons.folder),
        label: 'Создать иконку',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      if (widget.importOtpCodes != null)
        ActionButton(
          onPressed: () => _executeAction(widget.importOtpCodes!),
          icon: const Icon(Icons.qr_code),
          label: 'Импортировать OTP коды',
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      if (widget.migratePasswords != null)
        ActionButton(
          onPressed: () => _executeAction(widget.migratePasswords!),
          icon: const Icon(Icons.sync),
          label: 'Миграция паролей',
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateEntity),
        icon: widget.iconData != null
            ? Icon(widget.iconData)
            : const Icon(Icons.key),
        label: 'Создать ${widget.entityName}',
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ];
  }

  List<ActionButton> get actionButtons => _buildActionsList();

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.index,
    required this.spacing,
    required this.progress,
    required this.direction,
    this.fabOffset = Offset.zero,
    required this.child,
  });

  final int index;
  final double spacing;
  final Animation<double> progress;
  final FABExpandDirection direction;
  final Offset fabOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = progress.value * spacing * (index + 1);

        // Определяем позиционирование в зависимости от направления
        final double? left;
        final double? top;
        final double? bottom;

        if (direction == FABExpandDirection.right) {
          // Горизонтально вправо - кнопки лесенкой вниз
          left = fabOffset.dx + 80; // +8 для начального отступа
          top =
              fabOffset.dy + (index * 64); // Каждая кнопка чуть ниже предыдущей
          bottom = null;
        } else {
          // Вертикально вверх - кнопки центрированы относительно FAB
          // fabOffset.dx + 28 - это центр FAB (56/2 = 28)
          left = fabOffset.dx + 28; // Смещаем влево на половину ширины кнопки
          top = fabOffset.dy - 32 - offset; // Вычитаем, чтобы идти вверх
          bottom = null;
        }

        return Positioned(
          left: left,
          top: top,
          bottom: bottom,
          child: direction == FABExpandDirection.up
              ? Transform.translate(
                  offset: const Offset(
                    -0.5,
                    0,
                  ), // Смещаем влево на половину ширины кнопки
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Transform.scale(
                      scale: progress.value,
                      child: child!,
                    ),
                  ),
                )
              : Transform.scale(scale: progress.value, child: child!),
        );
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}

/// Overlay для отображения раскрывающихся кнопок поверх всего контента
class FABActionsOverlay extends StatelessWidget {
  const FABActionsOverlay({
    super.key,
    required this.isOpen,
    required this.animation,
    required this.actions,
    required this.direction,
    required this.spacing,
    required this.fabOffset,
    this.onBackdropTap,
    this.onCloseTap,
    this.showCloseButton = true,
  });

  final bool isOpen;
  final Animation<double> animation;
  final List<ActionButton> actions;
  final FABExpandDirection direction;
  final double spacing;
  final Offset fabOffset;
  final VoidCallback? onBackdropTap;
  final VoidCallback? onCloseTap;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Показываем overlay только когда есть прогресс анимации
        if (animation.value == 0.0) return const SizedBox.shrink();

        return Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Затемнение на весь экран с возможностью закрытия по клику
              GestureDetector(
                onTap: onBackdropTap,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity:
                      animation.value * 0.5, // Максимальная прозрачность 50%
                  child: Container(color: Colors.black),
                ),
              ),
              // Кнопки действий
              for (int i = 0; i < actions.length; i++)
                _ExpandingActionButton(
                  index: i,
                  spacing: spacing,
                  progress: animation,
                  direction: direction,
                  fabOffset: fabOffset,
                  child: actions[i],
                ),
              // Кнопка закрытия поверх всего (только для desktop)
              if (showCloseButton)
                Positioned(
                  left: fabOffset.dx + 1,
                  top: fabOffset.dy + 6,
                  child: AnimatedContainer(
                    transformAlignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      animation.value * 0.3 + 0.7, // От 1.0 до 0.7
                      animation.value * 0.3 + 0.7,
                      1.0,
                    ),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: animation.value, // Плавное появление
                      duration: const Duration(milliseconds: 250),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Material(
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          elevation: 4,
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            onTap: onCloseTap,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: foregroundColor, size: 20),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
