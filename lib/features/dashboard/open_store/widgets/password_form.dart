import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/dashboard/open_store/models/open_store_state.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Форма для ввода пароля при открытии хранилища
class PasswordForm extends StatefulWidget {
  final StorageInfo storage;
  final String password;
  final String? passwordError;
  final bool isOpening;
  final void Function(String) onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const PasswordForm({
    super.key,
    required this.storage,
    required this.password,
    required this.passwordError,
    required this.isOpening,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.password);
    _passwordController.addListener(_onPasswordChanged);
    _passwordFocusNode = FocusNode();
    // Автофокус на поле пароля
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  void _onPasswordChanged() {
    widget.onPasswordChanged(_passwordController.text);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          if (!widget.isOpening && widget.password.isNotEmpty) {
            widget.onSubmit();
            return KeyEventResult.handled;
          }
        } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          if (!widget.isOpening) {
            widget.onCancel();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Card(
        elevation: 0,
        // color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(
                    Icons.lock_outlined,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Открытие хранилища',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.storage.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Информация о хранилище
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Последнее изменение: ${widget.storage.formattedModifiedDate}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Размер: ${widget.storage.formattedSize}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Поле ввода пароля
              PasswordField(label: 'Пароль', controller: _passwordController),
              if (widget.passwordError != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.passwordError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SmoothButton(
                    label: 'Отмена',
                    type: SmoothButtonType.text,
                    onPressed: widget.isOpening ? null : widget.onCancel,
                  ),
                  const SizedBox(width: 12),
                  SmoothButton(
                    label: 'Открыть',
                    type: SmoothButtonType.filled,
                    loading: widget.isOpening,
                    onPressed: widget.isOpening || widget.password.isEmpty
                        ? null
                        : widget.onSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
