// ---------- Карточки для заметок ----------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Карточка заметки для режима списка
class NoteListCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const NoteListCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<NoteListCard> createState() => _NoteListCardState();
}

class _NoteListCardState extends ConsumerState<NoteListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _titleCopied = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _iconsController.forward();
    } else {
      _expandController.reverse();
      if (!_isHovered) {
        _iconsController.reverse();
      }
    }
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else if (!_isExpanded) {
      _iconsController.reverse();
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _copyTitle() async {
    await Clipboard.setData(ClipboardData(text: widget.note.title));
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Заголовок скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          borderOnForeground: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              MouseRegion(
                onEnter: (_) => _onHoverChanged(true),
                onExit: (_) => _onHoverChanged(false),
                child: InkWell(
                  onTap: _toggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Иконка
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Основная информация
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.note.category != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                      widget.note.category!.color,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _parseColor(
                                        widget.note.category!.color,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    widget.note.category!.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _parseColor(
                                        widget.note.category!.color,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              // Название
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.note.title,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.note.description != null &&
                                  widget.note.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.note.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Действия
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!widget.note.isDeleted) ...[
                              // Иконки состояния с анимацией
                              AnimatedBuilder(
                                animation: _iconsAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _iconsAnimation.value,
                                    child: Transform.scale(
                                      scale:
                                          0.8 + (_iconsAnimation.value * 0.2),
                                      alignment: Alignment.centerRight,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.note.isArchived)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.archive,
                                          size: 16,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    if (widget.note.usedCount >=
                                        MainConstants.popularItemThreshold)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.local_fire_department,
                                          size: 16,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Кнопки действия с анимацией
                              AnimatedBuilder(
                                animation: _iconsAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _iconsAnimation.value,
                                    child: Transform.scale(
                                      scale:
                                          0.8 + (_iconsAnimation.value * 0.2),
                                      alignment: Alignment.centerRight,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        widget.note.isPinned
                                            ? Icons.push_pin
                                            : Icons.push_pin_outlined,
                                        size: 18,
                                        color: widget.note.isPinned
                                            ? Colors.orange
                                            : null,
                                      ),
                                      onPressed: widget.onTogglePin,
                                      tooltip: widget.note.isPinned
                                          ? 'Открепить'
                                          : 'Закрепить',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        widget.note.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: widget.note.isFavorite
                                            ? Colors.amber
                                            : null,
                                      ),
                                      onPressed: widget.onToggleFavorite,
                                      tooltip: 'Избранное',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        context.push(
                                          AppRoutesPaths.dashboardNoteEditWithId(
                                            widget.note.id,
                                          ),
                                        );
                                      },
                                      tooltip: 'Редактировать',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            IconButton(
                              icon: Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                              onPressed: _toggleExpanded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Развернутый контент с анимацией
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Категория
                      if (widget.note.category != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(
                                  widget.note.category!.color,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _parseColor(
                                    widget.note.category!.color,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 14,
                                    color: _parseColor(
                                      widget.note.category!.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.note.category!.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _parseColor(
                                        widget.note.category!.color,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Описание
                      if (widget.note.description != null &&
                          widget.note.description!.isNotEmpty) ...[
                        Text(
                          'Описание:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.note.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Кнопки копирования
                      Row(
                        children: [
                          Expanded(
                            child: SmoothButton(
                              label: 'Заголовок',
                              onPressed: _copyTitle,
                              type: SmoothButtonType.outlined,
                              size: SmoothButtonSize.small,
                              variant: SmoothButtonVariant.normal,
                              icon: Icon(
                                _titleCopied ? Icons.check : Icons.title,
                                size: 16,
                              ),
                              iconPosition: SmoothButtonIconPosition.start,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SmoothButton(
                              label: 'Открыть',
                              onPressed: () {
                                context.push(
                                  AppRoutesPaths.dashboardNoteEditWithId(
                                    widget.note.id,
                                  ),
                                );
                              },
                              type: SmoothButtonType.outlined,
                              size: SmoothButtonSize.small,
                              variant: SmoothButtonVariant.normal,
                              icon: const Icon(Icons.open_in_new, size: 16),
                              iconPosition: SmoothButtonIconPosition.start,
                            ),
                          ),
                        ],
                      ),

                      // Теги
                      if (widget.note.tags != null &&
                          widget.note.tags!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Теги:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.note.tags!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final tag = widget.note.tags![index];
                              final tagColor = _parseColor(tag.color);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: tagColor.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.label,
                                      size: 12,
                                      color: tagColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tag.name,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: tagColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Метаинформация
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Использован: ${widget.note.usedCount} раз',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Изменён: ${_formatDate(widget.note.modifiedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Кнопки удаления и восстановления
                      Row(
                        children: [
                          if (widget.note.isDeleted) ...[
                            Expanded(
                              child: SmoothButton(
                                label: 'Восстановить',
                                onPressed: widget.onRestore,
                                type: SmoothButtonType.text,
                                size: SmoothButtonSize.small,
                                variant: SmoothButtonVariant.success,
                                icon: const Icon(Icons.restore, size: 16),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SmoothButton(
                                label: 'Удалить навсегда',
                                onPressed: widget.onDelete,
                                type: SmoothButtonType.text,
                                size: SmoothButtonSize.small,
                                variant: SmoothButtonVariant.error,
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 16,
                                ),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: SmoothButton(
                                label: widget.note.isArchived
                                    ? 'Разархивировать'
                                    : 'Архивировать',
                                onPressed: widget.onToggleArchive,
                                size: SmoothButtonSize.small,
                                type: SmoothButtonType.text,
                                variant: SmoothButtonVariant.info,
                                icon: Icon(
                                  widget.note.isArchived
                                      ? Icons.unarchive
                                      : Icons.archive,
                                  size: 16,
                                ),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SmoothButton(
                                label: 'Удалить',
                                onPressed: widget.onDelete,
                                size: SmoothButtonSize.small,
                                type: SmoothButtonType.text,
                                variant: SmoothButtonVariant.error,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.note.isPinned)
          Positioned(
            top: 2,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 20, color: Colors.orange),
            ),
          ),
        if (widget.note.isFavorite)
          Positioned(
            top: 2,
            left: widget.note.isPinned ? 34 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 18, color: Colors.amber),
            ),
          ),
        if (widget.note.isArchived)
          Positioned(
            top: 2,
            left: widget.note.isPinned || widget.note.isFavorite
                ? (widget.note.isFavorite ? 60 : 34)
                : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(
                Icons.archive,
                size: 18,
                color: Colors.blueGrey,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} мин назад';
      }
      return '${diff.inHours} ч назад';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} д назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Карточка заметки для режима сетки
class NoteGridCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const NoteGridCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<NoteGridCard> createState() => _NoteGridCardState();
}

class _NoteGridCardState extends ConsumerState<NoteGridCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

  @override
  void initState() {
    super.initState();
    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconsController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          child: MouseRegion(
            onEnter: (_) => _onHoverChanged(true),
            onExit: (_) => _onHoverChanged(false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!widget.note.isDeleted) ...[
                          // Иконки состояния с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.note.isArchived)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (widget.note.usedCount >=
                                    MainConstants.popularItemThreshold)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      size: 12,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Кнопки действия с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    widget.note.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 14,
                                    color: widget.note.isPinned
                                        ? Colors.orange
                                        : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onTogglePin,
                                ),
                                IconButton(
                                  icon: Icon(
                                    widget.note.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.note.isFavorite
                                        ? Colors.amber
                                        : null,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onToggleFavorite,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.push(
                                      AppRoutesPaths.dashboardNoteEditWithId(
                                        widget.note.id,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Для удалённых записей показываем кнопки восстановления и удаления
                          IconButton(
                            icon: const Icon(Icons.restore, size: 12),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onRestore,
                            tooltip: 'Восстановить',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 12,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onDelete,
                            tooltip: 'Удалить навсегда',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Категория
                    if (widget.note.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(
                            widget.note.category!.color,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.note.category!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _parseColor(widget.note.category!.color),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Название
                    Text(
                      widget.note.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Описание
                    if (widget.note.description != null &&
                        widget.note.description!.isNotEmpty)
                      Text(
                        widget.note.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Теги (горизонтальная прокрутка)
                    if (widget.note.tags != null &&
                        widget.note.tags!.isNotEmpty) ...[
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.note.tags!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = widget.note.tags![index];
                            final tagColor = _parseColor(tag.color);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tagColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Кнопка открытия заметки
                    SizedBox(
                      width: double.infinity,
                      child: SmoothButton(
                        label: 'Открыть',
                        onPressed: () {
                          context.push(
                            AppRoutesPaths.dashboardNoteEditWithId(
                              widget.note.id,
                            ),
                          );
                        },
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.normal,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        iconPosition: SmoothButtonIconPosition.start,
                        size: SmoothButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.note.isPinned)
          Positioned(
            top: 6,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            ),
          ),
        if (widget.note.isFavorite)
          Positioned(
            top: 6,
            left: widget.note.isPinned ? 30 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
