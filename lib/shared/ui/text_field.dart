import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Универсальный радиус по умолчанию
const BorderRadius defaultBorderRadiusValue = BorderRadius.all(
  Radius.circular(16),
);

/// Возвращает стандартный InputDecoration, основанный на закомментированном коде.
InputDecoration primaryInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? errorText,
  Widget? error,
  Widget? helper,
  String? helperText,
  bool enabled = true,
  bool filled = true,
  Widget? icon,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    error: error,
    enabled: enabled,
    helper: helper,
    helperText: helperText,
    icon: icon,

    labelStyle: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),

    border: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: const BorderSide(color: Colors.transparent, width: 0),
    ),
    filled: filled,
    errorBorder: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: BorderSide(color: Colors.transparent, width: 0),
    ),
    focusedErrorBorder: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: BorderSide(color: Colors.transparent, width: 0),
    ),

    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    floatingLabelStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    fillColor: theme.colorScheme.surfaceContainerHighest,
    enabledBorder: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: const BorderSide(color: Colors.transparent, width: 0),
    ),
    disabledBorder: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: const BorderSide(color: Colors.transparent, width: 0),
    ),

    focusedBorder: UnderlineInputBorder(
      borderRadius: defaultBorderRadiusValue,
      borderSide: const BorderSide(color: Colors.transparent, width: 0),
    ),
    helperStyle: TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    ),
  );
}

/// Простой обёрточный виджет для TextField с преднастроенной декорацией.
class PrimaryTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final String? hintText;
  final bool filled;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool? enabled;
  final bool autofocus;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorWidth;
  final double? cursorHeight;
  final bool enableSuggestions;
  final bool autocorrect;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets scrollPadding;
  final bool expands;

  const PrimaryTextField({
    super.key,
    this.label,
    this.controller,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.hintText,
    this.filled = true,
    this.decoration,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.showCursor,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.scrollPhysics,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.expands = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = primaryInputDecoration(
      context,
      labelText: label,
      hintText: hintText,
      filled: filled,
    );

    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(
          // allow short-hands (prefix/suffix) and icons to override
          prefixIcon: prefixIcon ?? (decoration?.prefixIcon),
          suffixIcon: suffixIcon ?? (decoration?.suffixIcon),
          prefix: prefix ?? decoration?.prefix,
          suffix: suffix ?? decoration?.suffix,
        )
        .copyWith(
          // ensure base defaults are present, but decoration overrides base
          labelText: decoration?.labelText ?? baseDecoration.labelText,
          hintText: decoration?.hintText ?? baseDecoration.hintText,
          fillColor: decoration?.fillColor ?? baseDecoration.fillColor,
          filled: decoration?.filled ?? baseDecoration.filled,
          border: decoration?.border ?? baseDecoration.border,
          enabledBorder:
              decoration?.enabledBorder ?? baseDecoration.enabledBorder,
          focusedBorder:
              decoration?.focusedBorder ?? baseDecoration.focusedBorder,
          errorBorder: decoration?.errorBorder ?? baseDecoration.errorBorder,
          floatingLabelStyle:
              decoration?.floatingLabelStyle ??
              baseDecoration.floatingLabelStyle,
        );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      textAlign: textAlign,
      style: style,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth ?? 2.0,
      cursorHeight: cursorHeight,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      scrollPhysics: scrollPhysics,
      scrollPadding: scrollPadding,
      expands: expands,
    );
  }
}

/// Простой обёрточный виджет для TextFormField с преднастроенной декорацией.
class PrimaryTextFormField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final String? hintText;
  final bool filled;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool? enabled;
  final bool autofocus;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final Color? cursorColor;
  final double? cursorWidth;
  final double? cursorHeight;
  final bool enableSuggestions;
  final bool autocorrect;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets scrollPadding;
  final bool expands;
  final AutovalidateMode? autovalidateMode;
  final String? initialValue;
  final String? helperText;

  const PrimaryTextFormField({
    super.key,
    this.label,
    this.controller,
    this.validator,
    this.onSaved,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.hintText,
    this.filled = true,
    this.decoration,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.showCursor,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.scrollPhysics,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.expands = false,
    this.autovalidateMode,
    this.initialValue,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = primaryInputDecoration(
      context,
      labelText: label,
      hintText: hintText,
      filled: filled,
    );

    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(
          prefixIcon: prefixIcon ?? (decoration?.prefixIcon),
          suffixIcon: suffixIcon ?? (decoration?.suffixIcon),
          prefix: prefix ?? decoration?.prefix,
          suffix: suffix ?? decoration?.suffix,
          helperText: helperText ?? decoration?.helperText,
        )
        .copyWith(
          labelText: decoration?.labelText ?? baseDecoration.labelText,
          hintText: decoration?.hintText ?? baseDecoration.hintText,
          fillColor: decoration?.fillColor ?? baseDecoration.fillColor,
          filled: decoration?.filled ?? baseDecoration.filled,
          border: decoration?.border ?? baseDecoration.border,
          enabledBorder:
              decoration?.enabledBorder ?? baseDecoration.enabledBorder,
          focusedBorder:
              decoration?.focusedBorder ?? baseDecoration.focusedBorder,
          errorBorder: decoration?.errorBorder ?? baseDecoration.errorBorder,
          floatingLabelStyle:
              decoration?.floatingLabelStyle ??
              baseDecoration.floatingLabelStyle,
        );

    return TextFormField(
      controller: controller,
      // initialValue is ignored if controller is provided (TextFormField rule)
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      onSaved: onSaved,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,

      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      textAlign: textAlign,
      style: style,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth ?? 2.0,
      cursorHeight: cursorHeight,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      scrollPhysics: scrollPhysics,
      scrollPadding: scrollPadding,
      expands: expands,
      autovalidateMode: autovalidateMode,
    );
  }
}

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      decoration: primaryInputDecoration(context, labelText: widget.label)
          .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            prefixIcon: const Icon(Icons.lock),
          ),
    );
  }
}
