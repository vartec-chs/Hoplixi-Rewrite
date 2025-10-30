import 'package:flutter/material.dart';

enum SmoothButtonType { text, filled, tonal, outlined }

enum SmoothButtonSize { small, medium, large }

enum SmoothButtonIconPosition { start, end }

/// A smooth button with customizable properties.
class SmoothButton extends StatelessWidget {
  final SmoothButtonType type;
  final SmoothButtonSize size;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final ButtonStyle? style;
  final Widget? icon;
  final SmoothButtonIconPosition iconPosition;
  final String label;
  final bool loading;
  final bool bold;
  final bool isFullWidth;

  const SmoothButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = SmoothButtonType.filled,
    this.size = SmoothButtonSize.medium,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.style,
    this.icon,
    this.iconPosition = SmoothButtonIconPosition.start,
    this.loading = false,
    this.bold = false,
    this.isFullWidth = false,
  });

  double get _fontSize {
    switch (size) {
      case SmoothButtonSize.small:
        return 14;
      case SmoothButtonSize.medium:
        return 16;
      case SmoothButtonSize.large:
        return 18;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case SmoothButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case SmoothButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 22, vertical: 18);
      case SmoothButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 26, vertical: 20);
    }
  }

  Widget _buildChild() {
    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _fontSize,
            height: _fontSize,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }

    if (icon != null) {
      final iconWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: icon,
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: iconPosition == SmoothButtonIconPosition.start
            ? [iconWidget, textWidget]
            : [textWidget, iconWidget],
      );
    }

    return textWidget;
  }

  Widget _buildButton(BuildContext context) {
    final buttonChild = _buildChild();

    final effectiveStyle = (style ?? ButtonStyle()).copyWith(
      padding: WidgetStateProperty.all(_padding),
    );

    switch (type) {
      case SmoothButtonType.text:
        return TextButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: effectiveStyle,
          child: buttonChild,
        );

      case SmoothButtonType.filled:
        return FilledButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: effectiveStyle,
          child: buttonChild,
        );

      case SmoothButtonType.tonal:
        return FilledButton.tonal(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: effectiveStyle,
          child: buttonChild,
        );

      case SmoothButtonType.outlined:
        return OutlinedButton(
          onPressed: loading ? null : onPressed,
          onLongPress: onLongPress,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          style: effectiveStyle.copyWith(
            side: WidgetStateProperty.all(
              BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.12),
                width: 1.5,
              ),
            ),
          ),
          child: buttonChild,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isFullWidth
        ? SizedBox(width: double.infinity, child: _buildButton(context))
        : _buildButton(context);
  }
}
