import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_modal.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Текстовое поле для выбора категории
class CategoryPickerField extends StatefulWidget {
  const CategoryPickerField({
    super.key,
    required this.onCategorySelected,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.label = 'Категория',
    this.hintText = 'Выберите категорию',
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе категории
  final Function(String? categoryId, String? categoryName) onCategorySelected;

  /// ID выбранной категории
  final String? selectedCategoryId;

  /// Имя выбранной категории
  final String? selectedCategoryName;

  /// Метка поля
  final String label;

  /// Подсказка
  final String hintText;

  /// Доступность поля
  final bool enabled;

  /// FocusNode для управления фокусом
  final FocusNode? focusNode;

  /// Автоматический фокус
  final bool autofocus;

  @override
  State<CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<CategoryPickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _effectiveFocusNode.requestFocus();
    _openPicker();
  }

  void _handleClear() {
    if (!widget.enabled) return;
    widget.onCategorySelected(null, null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    await CategoryPickerModal.show(
      context: context,
      currentCategoryId: widget.selectedCategoryId,
      onCategorySelected: (categoryId, categoryName) {
        widget.onCategorySelected(categoryId, categoryName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasValue =
        widget.selectedCategoryName != null &&
        widget.selectedCategoryName!.isNotEmpty;

    return Semantics(
      label: widget.label,
      hint: hasValue ? widget.selectedCategoryName : widget.hintText,
      button: true,
      enabled: widget.enabled,
      focusable: true,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onKeyEvent: (node, event) {
          if (!widget.enabled) return KeyEventResult.ignored;

          // Enter, Space - открыть пикер
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openPicker();
            return KeyEventResult.handled;
          }

          // Delete, Backspace - очистить выбор
          if (event is KeyDownEvent &&
              hasValue &&
              (event.logicalKey == LogicalKeyboardKey.delete ||
                  event.logicalKey == LogicalKeyboardKey.backspace)) {
            _handleClear();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _effectiveFocusNode,
          builder: (context, child) {
            final isFocused = _effectiveFocusNode.hasFocus;

            return InputDecorator(
              decoration: primaryInputDecoration(
                context,
                labelText: widget.label,
                hintText: widget.hintText,
                enabled: widget.enabled,
                isFocused: isFocused,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasValue)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: widget.enabled ? _handleClear : null,
                        tooltip: 'Очистить (Delete/Backspace)',
                      ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: widget.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ],
                ),
              ),
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(12),
                focusColor: colorScheme.primary.withOpacity(1),
                hoverColor: colorScheme.onSurface.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hasValue ? widget.selectedCategoryName! : widget.hintText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: hasValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
