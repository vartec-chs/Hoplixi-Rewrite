// ---------- Карточки для паролей ----------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Карточка пароля для режима списка
class PasswordListCard extends ConsumerStatefulWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const PasswordListCard({
    super.key,
    required this.password,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<PasswordListCard> createState() => _PasswordListCardState();
}

class _PasswordListCardState extends ConsumerState<PasswordListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _passwordCopied = false;
  bool _loginCopied = false;
  bool _urlCopied = false;
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

  String _extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
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

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );

    if (passwordText != null) {
      await Clipboard.setData(ClipboardData(text: passwordText));
      setState(() => _passwordCopied = true);
      Toaster.success(title: 'Пароль скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _passwordCopied = false);
      });
    } else {
      Toaster.error(title: 'Не удалось получить пароль');
    }
  }

  Future<void> _copyLogin() async {
    final text = widget.password.email ?? widget.password.login;
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      setState(() => _loginCopied = true);
      Toaster.success(title: 'Логин скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _loginCopied = false);
      });
    }
  }

  Future<void> _copyUrl() async {
    final url = widget.password.url;
    if (url != null && url.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: url));
      setState(() => _urlCopied = true);
      Toaster.success(title: 'URL скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _urlCopied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayLogin = widget.password.email ?? widget.password.login;
    final hostUrl = _extractHost(widget.password.url);

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
                            // color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Основная информация
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.password.category != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                      widget.password.category!.color,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _parseColor(
                                        widget.password.category!.color,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    widget.password.category!.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _parseColor(
                                        widget.password.category!.color,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              // Категория и название
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.password.name,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (displayLogin != null ||
                                  hostUrl.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (displayLogin != null) ...[
                                      Expanded(
                                        child: Text(
                                          displayLogin,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hostUrl.isNotEmpty)
                                        const SizedBox(width: 4),
                                    ],
                                    if (hostUrl.isNotEmpty)
                                      Text(
                                        hostUrl,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                              fontSize: 10,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Действия
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!widget.password.isDeleted) ...[
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
                                    if (widget.password.isArchived)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.archive,
                                          size: 16,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    if (widget.password.usedCount >=
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
                                        widget.password.isPinned
                                            ? Icons.push_pin
                                            : Icons.push_pin_outlined,
                                        size: 18,
                                        color: widget.password.isPinned
                                            ? Colors.orange
                                            : null,
                                      ),
                                      onPressed: widget.onTogglePin,
                                      tooltip: widget.password.isPinned
                                          ? 'Открепить'
                                          : 'Закрепить',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        widget.password.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: widget.password.isFavorite
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
                                          AppRoutesPaths.dashboardPasswordEditWithId(
                                            widget.password.id,
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
                      if (widget.password.category != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(
                                  widget.password.category!.color,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _parseColor(
                                    widget.password.category!.color,
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
                                      widget.password.category!.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.password.category!.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _parseColor(
                                        widget.password.category!.color,
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
                      if (widget.password.description != null &&
                          widget.password.description!.isNotEmpty) ...[
                        Text(
                          'Описание:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.password.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Кнопки копирования
                      Row(
                        children: [
                          Expanded(
                            child: SmoothButton(
                              label: 'Пароль',
                              onPressed: _copyPassword,
                              type: SmoothButtonType.outlined,
                              size: SmoothButtonSize.small,
                              variant: SmoothButtonVariant.normal,
                              icon: Icon(
                                _passwordCopied ? Icons.check : Icons.lock,
                                size: 16,
                              ),
                              iconPosition: SmoothButtonIconPosition.start,
                            ),
                          ),
                          if (displayLogin != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: SmoothButton(
                                label: 'Логин',
                                onPressed: _copyLogin,
                                type: SmoothButtonType.outlined,
                                size: SmoothButtonSize.small,
                                variant: SmoothButtonVariant.normal,
                                icon: Icon(
                                  _loginCopied ? Icons.check : Icons.person,
                                  size: 16,
                                ),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                          ],
                          if (widget.password.url != null &&
                              widget.password.url!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: SmoothButton(
                                label: 'URL',
                                onPressed: _copyUrl,
                                type: SmoothButtonType.outlined,
                                size: SmoothButtonSize.small,
                                variant: SmoothButtonVariant.normal,
                                icon: Icon(
                                  _urlCopied ? Icons.check : Icons.link,
                                  size: 16,
                                ),
                                iconPosition: SmoothButtonIconPosition.start,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Теги
                      if (widget.password.tags != null &&
                          widget.password.tags!.isNotEmpty) ...[
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
                            itemCount: widget.password.tags!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final tag = widget.password.tags![index];
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
                            'Использован: ${widget.password.usedCount} раз',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Изменён: ${_formatDate(widget.password.modifiedAt)}',
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
                          if (widget.password.isDeleted) ...[
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
                                label: widget.password.isArchived
                                    ? 'Разархивировать'
                                    : 'Архивировать',
                                onPressed: widget.onToggleArchive,
                                size: SmoothButtonSize.small,
                                type: SmoothButtonType.text,
                                variant: SmoothButtonVariant.info,
                                icon: Icon(
                                  widget.password.isArchived
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
        if (widget.password.isPinned)
          Positioned(
            top: 2,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 20, color: Colors.orange),
            ),
          ),
        if (widget.password.isFavorite)
          Positioned(
            top: 2,
            // if pinned also present - shift favorite a bit to the right
            left: widget.password.isPinned ? 34 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 18, color: Colors.amber),
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

/// Карточка пароля для режима сетки
class PasswordGridCard extends ConsumerStatefulWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;

  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const PasswordGridCard({
    super.key,
    required this.password,
    this.onTap,

    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<PasswordGridCard> createState() => _PasswordGridCardState();
}

class _PasswordGridCardState extends ConsumerState<PasswordGridCard>
    with TickerProviderStateMixin {
  bool _passwordCopied = false;
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

  String _extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
    }
  }

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );

    if (passwordText != null) {
      await Clipboard.setData(ClipboardData(text: passwordText));
      setState(() => _passwordCopied = true);
      Toaster.success(title: 'Пароль скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _passwordCopied = false);
      });
    } else {
      Toaster.error(title: 'Не удалось получить пароль');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayLogin = widget.password.email ?? widget.password.login;
    final hostUrl = _extractHost(widget.password.url);

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
                            Icons.lock,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!widget.password.isDeleted) ...[
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
                                if (widget.password.isArchived)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (widget.password.usedCount >=
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
                                    widget.password.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 14,
                                    color: widget.password.isPinned
                                        ? Colors.orange
                                        : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onTogglePin,
                                ),
                                IconButton(
                                  icon: Icon(
                                    widget.password.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.password.isFavorite
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
                                      AppRoutesPaths.dashboardPasswordEditWithId(
                                        widget.password.id,
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
                    if (widget.password.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(
                            widget.password.category!.color,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.password.category!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _parseColor(widget.password.category!.color),
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
                      widget.password.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Логин/email
                    if (displayLogin != null)
                      Text(
                        displayLogin,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // URL
                    if (hostUrl.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hostUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const Spacer(),

                    // Теги (горизонтальная прокрутка)
                    if (widget.password.tags != null &&
                        widget.password.tags!.isNotEmpty) ...[
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.password.tags!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = widget.password.tags![index];
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

                    // Кнопка копирования пароля
                    SizedBox(
                      width: double.infinity,
                      child: SmoothButton(
                        label: _passwordCopied ? 'Скопировано' : 'Копировать',
                        onPressed: _copyPassword,
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.normal,
                        icon: Icon(
                          _passwordCopied ? Icons.check : Icons.copy,
                          size: 14,
                        ),
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
        if (widget.password.isPinned)
          Positioned(
            top: 6,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            ),
          ),
        if (widget.password.isFavorite)
          Positioned(
            top: 6,
            left: widget.password.isPinned ? 30 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
