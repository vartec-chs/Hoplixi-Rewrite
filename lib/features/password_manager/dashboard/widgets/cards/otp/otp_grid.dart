// ---------- Карточки для OTP (TOTP) ----------

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:otp/otp.dart';

/// Карточка TOTP для режима сетки (Grid)
class TotpGridCard extends ConsumerStatefulWidget {
  final OtpCardDto otp;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const TotpGridCard({
    super.key,
    required this.otp,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<TotpGridCard> createState() => _TotpGridCardState();
}

class _TotpGridCardState extends ConsumerState<TotpGridCard>
    with TickerProviderStateMixin {
  bool _codeCopied = false;
  bool _isLoadingSecret = false;
  bool _isCodeVisible = false;

  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

  // TOTP state
  Uint8List? _secret;
  String? _currentCode;
  int _remainingSeconds = 0;
  Timer? _totpTimer;

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
    _clearSecret();
    _totpTimer?.cancel();
    _iconsController.dispose();
    super.dispose();
  }

  /// Очищает секрет из памяти
  void _clearSecret() {
    if (_secret != null) {
      for (int i = 0; i < _secret!.length; i++) {
        _secret![i] = 0;
      }
      _secret = null;
    }
    _currentCode = null;
  }

  void _onHoverChanged(bool isHovered) {
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  /// Переключает видимость кода
  void _toggleCodeVisibility() {
    if (_isCodeVisible) {
      _stopTimerAndClearSecret();
      setState(() => _isCodeVisible = false);
    } else {
      _loadSecretAndStartTimer();
      setState(() => _isCodeVisible = true);
    }
  }

  /// Загружает секрет из БД и запускает таймер генерации кода
  Future<void> _loadSecretAndStartTimer() async {
    if (_secret != null) {
      _generateCode();
      _startTimer();
      return;
    }

    setState(() => _isLoadingSecret = true);

    try {
      final otpDao = await ref.read(otpDaoProvider.future);
      final secretBytes = await otpDao.getOtpSecretById(widget.otp.id);

      if (secretBytes != null && mounted) {
        setState(() {
          _secret = secretBytes;
          _isLoadingSecret = false;
        });
        _generateCode();
        _startTimer();
      } else {
        if (mounted) {
          setState(() => _isLoadingSecret = false);
          Toaster.error(title: 'Не удалось получить секрет OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSecret = false);
        Toaster.error(title: 'Ошибка загрузки секрета', description: '$e');
      }
    }
  }

  /// Останавливает таймер и очищает секрет
  void _stopTimerAndClearSecret() {
    _totpTimer?.cancel();
    _totpTimer = null;
    _clearSecret();
    setState(() {
      _remainingSeconds = 0;
    });
  }

  /// Запускает таймер обновления кода
  void _startTimer() {
    _totpTimer?.cancel();
    _updateRemainingSeconds();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCodeVisible) {
        timer.cancel();
        return;
      }

      _updateRemainingSeconds();

      if (_remainingSeconds == widget.otp.period || _remainingSeconds == 0) {
        _generateCode();
      }
    });
  }

  /// Обновляет оставшееся время до смены кода
  void _updateRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = widget.otp.period;
    setState(() {
      _remainingSeconds = period - (now % period);
    });
  }

  /// Генерирует TOTP код
  void _generateCode() {
    if (_secret == null) return;

    try {
      // Секрет в БД хранится как ASCII коды Base32 строки (codeUnits),
      // поэтому просто конвертируем байты обратно в строку
      final secretBase32 = String.fromCharCodes(_secret!);

      final code = OTP.generateTOTPCodeString(
        secretBase32,
        DateTime.now().millisecondsSinceEpoch,
        length: widget.otp.digits,
        interval: widget.otp.period,
        algorithm: Algorithm.SHA1,
        isGoogle: true, // true = секрет передаётся как Base32 строка
      );

      setState(() {
        _currentCode = code;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка генерации кода', description: '$e');
    }
  }

  Future<void> _copyCode() async {
    if (_currentCode == null) return;

    await Clipboard.setData(ClipboardData(text: _currentCode!));
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
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

  /// Форматирует код с разделением (например: "123 456")
  String _formatCode(String code) {
    if (code.length <= 3) return code;

    final buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.otp.issuer ?? widget.otp.accountName ?? 'OTP';
    final subtitle = widget.otp.issuer != null ? widget.otp.accountName : null;
    final progress = _remainingSeconds / widget.otp.period;
    final isLowTime = _remainingSeconds <= 5;

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
                    // Заголовок с иконкой и кнопками
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
                            Icons.security,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!widget.otp.isDeleted) ...[
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
                                if (widget.otp.isArchived)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (widget.otp.usedCount >=
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
                                    widget.otp.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 14,
                                    color: widget.otp.isPinned
                                        ? Colors.orange
                                        : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onTogglePin,
                                ),
                                IconButton(
                                  icon: Icon(
                                    widget.otp.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.otp.isFavorite
                                        ? Colors.amber
                                        : null,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onToggleFavorite,
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
                    if (widget.otp.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(
                            widget.otp.category!.color,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.otp.category!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _parseColor(widget.otp.category!.color),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Название (issuer)
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Подзаголовок (accountName)
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Теги (горизонтальная прокрутка)
                    if (widget.otp.tags != null &&
                        widget.otp.tags!.isNotEmpty) ...[
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.otp.tags!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = widget.otp.tags![index];
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

                    // Секция кода или кнопка показа
                    if (_isCodeVisible) ...[
                      // Код TOTP
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLowTime
                                ? Colors.red.withOpacity(0.5)
                                : theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_isLoadingSecret)
                              const SizedBox(
                                height: 24,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            else if (_currentCode != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatCode(_currentCode!),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                            color: isLowTime
                                                ? Colors.red
                                                : null,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _codeCopied ? Icons.check : Icons.copy,
                                      size: 16,
                                      color: _codeCopied ? Colors.green : null,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: _copyCode,
                                    tooltip: 'Копировать',
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            // Прогресс-бар
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 3,
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                        isLowTime
                                            ? Colors.red
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_remainingSeconds}с',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isLowTime
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Кнопка скрытия
                      SizedBox(
                        width: double.infinity,
                        child: SmoothButton(
                          label: 'Скрыть',
                          onPressed: _toggleCodeVisibility,
                          type: SmoothButtonType.text,
                          variant: SmoothButtonVariant.normal,
                          icon: const Icon(Icons.visibility_off, size: 14),
                          iconPosition: SmoothButtonIconPosition.start,
                          size: SmoothButtonSize.small,
                        ),
                      ),
                    ] else ...[
                      // Кнопка показа кода
                      SizedBox(
                        width: double.infinity,
                        child: SmoothButton(
                          label: 'Показать код',
                          onPressed: _toggleCodeVisibility,
                          type: SmoothButtonType.outlined,
                          variant: SmoothButtonVariant.normal,
                          icon: const Icon(Icons.visibility, size: 14),
                          iconPosition: SmoothButtonIconPosition.start,
                          size: SmoothButtonSize.small,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.otp.isPinned)
          Positioned(
            top: 6,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            ),
          ),
        if (widget.otp.isFavorite)
          Positioned(
            top: 6,
            left: widget.otp.isPinned ? 30 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
