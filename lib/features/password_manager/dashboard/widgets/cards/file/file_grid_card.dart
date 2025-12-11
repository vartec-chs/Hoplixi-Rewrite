import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';

class FileGridCard extends ConsumerStatefulWidget {
  final FileCardDto file;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;

  const FileGridCard({
    super.key,
    required this.file,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
  });

  @override
  ConsumerState<FileGridCard> createState() => _FileGridCardState();
}

class _FileGridCardState extends ConsumerState<FileGridCard>
    with TickerProviderStateMixin {
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
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = widget.file;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
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
                    // Заголовок (Иконка + Меню)
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons
                                .insert_drive_file, // TODO: Icon based on extension
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!file.isDeleted) ...[
                          // Анимированные действия
                          FadeTransition(
                            opacity: _iconsAnimation,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    file.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 20,
                                    color: file.isFavorite
                                        ? Colors.amber
                                        : null,
                                  ),
                                  onPressed: widget.onToggleFavorite,
                                  tooltip: file.isFavorite
                                      ? 'Убрать из избранного'
                                      : 'В избранное',
                                ),
                                IconButton(
                                  icon: Icon(
                                    file.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 20,
                                    color: file.isPinned ? Colors.orange : null,
                                  ),
                                  onPressed: widget.onTogglePin,
                                  tooltip: file.isPinned
                                      ? 'Открепить'
                                      : 'Закрепить',
                                ),
                                IconButton(
                                  icon: Icon(
                                    file.isArchived
                                        ? Icons.unarchive
                                        : Icons.archive,
                                    size: 20,
                                  ),
                                  onPressed: widget.onToggleArchive,
                                  tooltip: file.isArchived
                                      ? 'Разархивировать'
                                      : 'Архивировать',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  onPressed: widget.onDelete,
                                  tooltip: 'Удалить',
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(
                              Icons.restore_from_trash,
                              size: 20,
                            ),
                            onPressed: widget.onRestore,
                            tooltip: 'Восстановить',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: widget.onDelete,
                            tooltip: 'Удалить навсегда',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Категория
                    if (file.category != null) ...[
                      CardCategoryBadge(
                        name: file.category!.name,
                        color: file.category!.color,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Название
                    Text(
                      file.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Имя файла
                    Text(
                      file.fileName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Размер и расширение
                    const SizedBox(height: 2),
                    Text(
                      '${file.fileExtension.toUpperCase()} • ${_formatFileSize(file.fileSize)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Теги
                    if (file.tags != null && file.tags!.isNotEmpty) ...[
                      CardTagsList(tags: file.tags!),
                      const SizedBox(height: 8),
                    ],

                    // Кнопка расшифровки
                    SizedBox(
                      width: double.infinity,
                      child: SmoothButton(
                        label: 'Расшифровать',
                        onPressed: widget.onDecrypt,
                        icon: const Icon(Icons.lock_open, size: 16),
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.normal,
                        size: SmoothButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Индикаторы
        ...CardStatusIndicators(
          isPinned: file.isPinned,
          isFavorite: file.isFavorite,
          isArchived: file.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }
}
