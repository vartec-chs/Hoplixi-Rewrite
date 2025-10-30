import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Типы Slider Button для различных действий
enum SliderButtonType { confirm, delete, unlock, send }

/// Данные темы для Slider Button
class SliderButtonThemeData {
  final Color backgroundColor;
  final Color fillColor;
  final Color thumbColor;
  final Color iconColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final TextStyle textStyle;
  final double thumbSize;
  final Duration animationDuration;
  final IconData icon;

  const SliderButtonThemeData({
    required this.backgroundColor,
    required this.fillColor,
    required this.thumbColor,
    required this.iconColor,
    required this.textColor,
    required this.height,
    required this.borderRadius,
    required this.textStyle,
    required this.thumbSize,
    required this.animationDuration,
    required this.icon,
  });

  SliderButtonThemeData copyWith({
    Color? backgroundColor,
    Color? fillColor,
    Color? thumbColor,
    Color? iconColor,
    Color? textColor,
    double? height,
    double? borderRadius,
    TextStyle? textStyle,
    double? thumbSize,
    Duration? animationDuration,
    IconData? icon,
  }) {
    return SliderButtonThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fillColor: fillColor ?? this.fillColor,
      thumbColor: thumbColor ?? this.thumbColor,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      textStyle: textStyle ?? this.textStyle,
      thumbSize: thumbSize ?? this.thumbSize,
      animationDuration: animationDuration ?? this.animationDuration,
      icon: icon ?? this.icon,
    );
  }
}

/// Inherited Widget для передачи темы Slider Button
class SliderButtonTheme extends InheritedWidget {
  final SliderButtonThemeData data;

  const SliderButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static SliderButtonThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SliderButtonTheme>()
        ?.data;
  }

  static SliderButtonThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    if (theme != null) return theme;

    // Fallback к базовой теме на основе Material Theme
    final materialTheme = Theme.of(context);
    return _getDefaultTheme(materialTheme, SliderButtonType.confirm);
  }

  @override
  bool updateShouldNotify(SliderButtonTheme oldWidget) {
    return data != oldWidget.data;
  }
}

/// Основной компонент Slider Button
class SliderButton extends StatefulWidget {
  final SliderButtonType type;
  final String text;
  final VoidCallback? onSlideComplete;
  final SliderButtonThemeData? theme;
  final bool enabled;
  final double? width;
  final bool resetAfterComplete;
  final Duration resetDelay;
  final bool showLoading;
  final Future<void> Function()? onSlideCompleteAsync;

  const SliderButton({
    super.key,
    required this.type,
    required this.text,
    this.onSlideComplete,
    this.onSlideCompleteAsync,
    this.theme,
    this.enabled = true,
    this.width,
    this.resetAfterComplete = true,
    this.resetDelay = const Duration(milliseconds: 500),
    this.showLoading = false,
  });

  @override
  State<SliderButton> createState() => _SliderButtonState();
}

class _SliderButtonState extends State<SliderButton>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  double _dragPosition = 0.0;
  bool _isDragging = false;
  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Запускаем пульсацию при инициализации
    _startPulse();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPulse() {
    if (!_isDragging && !_isCompleted && !_isLoading && widget.enabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _isDragging = true;
    });
    _stopPulse();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxWidth);
    });
  }

  void _onPanEnd(
    DragEndDetails details,
    double maxWidth,
    SliderButtonThemeData theme,
  ) {
    if (!widget.enabled || _isCompleted || _isLoading) return;

    setState(() {
      _isDragging = false;
    });

    // Проверяем, достиг ли слайдер конца
    if (_dragPosition >= maxWidth * 0.8) {
      _completeSlide(theme);
    } else {
      _resetSlide();
    }
  }

  void _completeSlide(SliderButtonThemeData theme) async {
    if (widget.showLoading) {
      setState(() {
        _isLoading = true;
        _dragPosition = _getMaxDragDistance();
      });

      HapticFeedback.mediumImpact();

      try {
        // Выполняем асинхронное действие если есть
        if (widget.onSlideCompleteAsync != null) {
          await widget.onSlideCompleteAsync!();
        } else {
          widget.onSlideComplete?.call();
        }

        // Показываем анимацию завершения после загрузки
        setState(() {
          _isLoading = false;
          _isCompleted = true;
        });

        _slideController.forward();
      } catch (e) {
        // В случае ошибки сбрасываем состояние
        setState(() {
          _isLoading = false;
        });
        _resetSlide();
        return;
      }
    } else {
      // Обычная логика без загрузки
      setState(() {
        _isCompleted = true;
        _dragPosition = _getMaxDragDistance();
      });

      HapticFeedback.mediumImpact();
      _slideController.forward();

      if (widget.onSlideCompleteAsync != null) {
        widget.onSlideCompleteAsync!();
      } else {
        widget.onSlideComplete?.call();
      }
    }

    if (widget.resetAfterComplete) {
      Future.delayed(widget.resetDelay, () {
        if (mounted) {
          _resetSlide();
        }
      });
    }
  }

  void _resetSlide() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _dragPosition = 0.0;
          _isCompleted = false;
          _isLoading = false;
        });
        _startPulse();
      }
    });
  }

  double _getMaxDragDistance() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0.0;

    final theme = widget.theme ?? SliderButtonTheme.of(context);
    return renderBox.size.width - theme.thumbSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? SliderButtonTheme.of(context);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: SizedBox(
        width: widget.width,
        height: theme.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxDragDistance = constraints.maxWidth - theme.thumbSize;

            return Container(
              decoration: BoxDecoration(
                color: widget.enabled
                    ? theme.backgroundColor
                    : theme.backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(theme.borderRadius),
                border: widget.enabled
                    ? null
                    : Border.all(
                        color: theme.textColor.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Stack(
                children: [
                  // Заливка фона при движении
                  AnimatedContainer(
                    duration: _isDragging
                        ? Duration.zero
                        : theme.animationDuration,
                    width: _dragPosition + theme.thumbSize,
                    height: theme.height,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? theme.fillColor.withOpacity(0.3)
                          : theme.fillColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                  ),

                  // Текст
                  Center(
                    child: AnimatedOpacity(
                      duration: theme.animationDuration,
                      opacity: _isCompleted ? 0.0 : 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!widget.enabled) ...[
                            Icon(
                              Icons.lock_outline,
                              color: theme.textColor.withOpacity(0.5),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_isLoading) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Загрузка...',
                              style: theme.textStyle.copyWith(
                                color: theme.textColor,
                              ),
                            ),
                          ] else ...[
                            Text(
                              widget.text,
                              style: theme.textStyle.copyWith(
                                color: widget.enabled
                                    ? theme.textColor
                                    : theme.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Thumb (ползунок)
                  AnimatedPositioned(
                    duration: _isDragging
                        ? Duration.zero
                        : theme.animationDuration,
                    left: _dragPosition,
                    top: (theme.height - theme.thumbSize) / 2,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: (details) =>
                          _onPanUpdate(details, maxDragDistance),
                      onPanEnd: (details) =>
                          _onPanEnd(details, maxDragDistance, theme),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isDragging ? 1.1 : _pulseAnimation.value,
                            child: Container(
                              width: theme.thumbSize,
                              height: theme.thumbSize,
                              decoration: BoxDecoration(
                                color: widget.enabled
                                    ? theme.thumbColor
                                    : theme.thumbColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                                boxShadow: widget.enabled
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: theme.thumbSize * 0.6,
                                      height: theme.thumbSize * 0.6,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.iconColor,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      theme.icon,
                                      color: widget.enabled
                                          ? theme.iconColor
                                          : theme.iconColor.withOpacity(0.3),
                                      size: theme.thumbSize * 0.5,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Анимация завершения
                  if (_isCompleted)
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Container(
                          width: constraints.maxWidth * _slideAnimation.value,
                          height: theme.height,
                          decoration: BoxDecoration(
                            color: theme.fillColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(
                              theme.borderRadius,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check,
                              color: theme.iconColor,
                              size: theme.thumbSize * 0.6,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Функция для получения темы по умолчанию на основе типа кнопки
SliderButtonThemeData _getDefaultTheme(
  ThemeData materialTheme,
  SliderButtonType type,
) {
  final colorScheme = materialTheme.colorScheme;

  switch (type) {
    case SliderButtonType.confirm:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        fillColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        iconColor: colorScheme.onPrimary,
        textColor: colorScheme.onSurface,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: materialTheme.textTheme.bodyLarge ?? const TextStyle(),
        thumbSize: 48.0,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icons.arrow_forward_ios,
      );

    case SliderButtonType.delete:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
        fillColor: colorScheme.error,
        thumbColor: colorScheme.error,
        iconColor: colorScheme.onError,
        textColor: colorScheme.onErrorContainer,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: materialTheme.textTheme.bodyLarge ?? const TextStyle(),
        thumbSize: 48.0,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icons.delete_outline,
      );

    case SliderButtonType.unlock:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
        fillColor: colorScheme.secondary,
        thumbColor: colorScheme.secondary,
        iconColor: colorScheme.onSecondary,
        textColor: colorScheme.onSecondaryContainer,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: materialTheme.textTheme.bodyLarge ?? const TextStyle(),
        thumbSize: 48.0,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icons.lock_open_outlined,
      );

    case SliderButtonType.send:
      return SliderButtonThemeData(
        backgroundColor: colorScheme.tertiaryContainer.withOpacity(0.5),
        fillColor: colorScheme.tertiary,
        thumbColor: colorScheme.tertiary,
        iconColor: colorScheme.onTertiary,
        textColor: colorScheme.onTertiaryContainer,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: materialTheme.textTheme.bodyLarge ?? const TextStyle(),
        thumbSize: 48.0,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icons.send_outlined,
      );
  }
}

/// Предопределенные темы для быстрого использования
class SliderButtonThemes {
  static SliderButtonThemeData confirm(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.confirm);
  }

  static SliderButtonThemeData delete(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.delete);
  }

  static SliderButtonThemeData unlock(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.unlock);
  }

  static SliderButtonThemeData send(BuildContext context) {
    return _getDefaultTheme(Theme.of(context), SliderButtonType.send);
  }
}
