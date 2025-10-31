import 'package:flutter/material.dart';

/// Кнопка действия с иконкой, заголовком и описанием
class ActionButton extends StatelessWidget {
  /// Иконка кнопки
  final IconData icon;

  /// Заголовок кнопки
  final String label;

  /// Описание кнопки (опционально)
  final String? description;

  /// Является ли кнопка основной (primary)
  final bool isPrimary;

  /// Обработчик нажатия
  final VoidCallback? onTap;

  /// Включена ли кнопка
  final bool enabled;

  /// Отключена ли кнопка (приоритет над enabled)
  final bool disabled;

  /// Фиксированная высота кнопки (если не указана, используется адаптивная)
  final double? height;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.isPrimary = false,
    this.onTap,
    this.enabled = true,
    this.disabled = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Проверяем: если disabled=true, то кнопка отключена, иначе используем enabled
    final isDisabled = disabled || !enabled;

    // Определяем цвета в зависимости от типа кнопки
    final backgroundColor = isPrimary
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final disabledBackgroundColor = isPrimary
        ? colorScheme.primary.withOpacity(0.38)
        : colorScheme.surfaceContainerHighest.withOpacity(0.38);
    final disabledForegroundColor = foregroundColor.withOpacity(0.38);

    // Адаптивная высота: если не указана, используем в зависимости от наличия описания
    final buttonHeight = height ?? (description != null ? 100.0 : 70.0);

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary && !isDisabled
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        elevation: 0,
        color: isDisabled ? disabledBackgroundColor : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Иконка с фоном
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDisabled
                        ? disabledForegroundColor.withOpacity(0.1)
                        : foregroundColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDisabled
                        ? disabledForegroundColor
                        : foregroundColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Текстовое содержимое
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDisabled
                              ? disabledForegroundColor
                              : foregroundColor,
                          fontWeight: isPrimary
                              ? FontWeight.bold
                              : FontWeight.w600,
                          letterSpacing: isPrimary ? 0.5 : 0,
                        ),
                      ),
                      // Описание (если есть)
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDisabled
                                ? disabledForegroundColor
                                : foregroundColor.withOpacity(0.65),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Стрелка (если кнопка включена)
                if (!isDisabled) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: foregroundColor.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
