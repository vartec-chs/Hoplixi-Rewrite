import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/widgets/category_picker_modal.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Текстовое поле для выбора категории
class CategoryPickerField extends StatefulWidget {
  const CategoryPickerField({
    super.key,
    this.onCategorySelected,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.label = 'Категория',
    this.hintText = 'Выберите категорию',
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.isFilter = false, // режим фильтра
    this.selectedCategoryIds = const [], // режим фильтра
    this.selectedCategoryNames = const [], // режим фильтра
    this.filterByType, // режим фильтра
    this.onCategoriesSelected, // режим фильтра
  });

  /// Коллбэк при выборе категории (одиночный режим)
  final Function(String? categoryId, String? categoryName)? onCategorySelected;

  /// Коллбэк при выборе категорий (режим фильтра)
  final Function(List<String> categoryIds, List<String> categoryNames)?
  onCategoriesSelected;

  /// ID выбранной категории (одиночный режим)
  final String? selectedCategoryId;

  /// Имя выбранной категории (одиночный режим)
  final String? selectedCategoryName;

  /// ID выбранных категорий (режим фильтра)
  final List<String> selectedCategoryIds;

  /// Имена выбранных категорий (режим фильтра)
  final List<String> selectedCategoryNames;

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

  /// Режим фильтра (множественный выбор)
  final bool isFilter;

  /// Тип категорий для фильтрации (только в режиме фильтра)
  final CategoryType? filterByType;

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
    if (widget.isFilter) {
      widget.onCategoriesSelected?.call([], []);
    } else {
      widget.onCategorySelected?.call(null, null);
    }
    _effectiveFocusNode.requestFocus();
  }

  void _handleRemoveCategory(int index) {
    if (!widget.enabled || !widget.isFilter) return;
    final updatedIds = List<String>.from(widget.selectedCategoryIds);
    final updatedNames = List<String>.from(widget.selectedCategoryNames);
    updatedIds.removeAt(index);
    updatedNames.removeAt(index);
    widget.onCategoriesSelected?.call(updatedIds, updatedNames);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    if (widget.isFilter) {
      // Режим фильтра - множественный выбор
      await CategoryPickerModal.showMultiple(
        context: context,
        currentCategoryIds: widget.selectedCategoryIds,
        filterByType: widget.filterByType?.value,
        onCategoriesSelected: (categoryIds, categoryNames) {
          widget.onCategoriesSelected?.call(categoryIds, categoryNames);
        },
      );
    } else {
      // Обычный режим - одиночный выбор
      await CategoryPickerModal.show(
        context: context,
        currentCategoryId: widget.selectedCategoryId,
        onCategorySelected: (categoryId, categoryName) {
          widget.onCategorySelected?.call(categoryId, categoryName);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Определяем наличие значения в зависимости от режима
    final hasValue = widget.isFilter
        ? widget.selectedCategoryNames.isNotEmpty
        : (widget.selectedCategoryName != null &&
              widget.selectedCategoryName!.isNotEmpty);

    return Semantics(
      label: widget.label,
      hint: hasValue
          ? (widget.isFilter
                ? '${widget.selectedCategoryNames.length} категорий выбрано'
                : widget.selectedCategoryName)
          : widget.hintText,
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
                        tooltip: widget.isFilter
                            ? 'Очистить все (Delete/Backspace)'
                            : 'Очистить (Delete/Backspace)',
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
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: widget.isFilter && hasValue
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            widget.selectedCategoryNames.length,
                            (index) => _CategoryChip(
                              label: widget.selectedCategoryNames[index],
                              onRemove: widget.enabled
                                  ? () => _handleRemoveCategory(index)
                                  : null,
                              enabled: widget.enabled,
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hasValue
                                ? widget.selectedCategoryName!
                                : widget.hintText,
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

/// Чип для отображения выбранной категории в режиме фильтра
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    this.onRemove,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? colorScheme.secondary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category,
            size: 14,
            color: enabled
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.close,
                size: 16,
                color: enabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
