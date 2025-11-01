import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/dashboard/create_store/providers/create_store_form_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Шаг 3: Мастер пароль
class Step3MasterPassword extends ConsumerStatefulWidget {
  const Step3MasterPassword({super.key});

  @override
  ConsumerState<Step3MasterPassword> createState() =>
      _Step3MasterPasswordState();
}

class _Step3MasterPasswordState extends ConsumerState<Step3MasterPassword> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmationController;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createStoreFormProvider);
    _passwordController = TextEditingController(text: state.password);
    _confirmationController = TextEditingController(
      text: state.passwordConfirmation,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createStoreFormProvider);
    final notifier = ref.read(createStoreFormProvider.notifier);

    return SingleChildScrollView(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Мастер пароль',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте надежный пароль для защиты вашего хранилища',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Поле пароля
          TextField(
            controller: _passwordController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Мастер пароль *',
              hintText: 'Минимум 4 символов',
              errorText: state.passwordError,
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: notifier.updatePassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),

          // Индикатор сложности пароля
          if (state.password.isNotEmpty)
            _PasswordStrengthIndicator(password: state.password),
          const SizedBox(height: 24),

          // Поле подтверждения
          TextField(
            controller: _confirmationController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Подтвердите пароль *',
              hintText: 'Введите пароль еще раз',
              errorText: state.passwordConfirmationError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmation = !_obscureConfirmation;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmation,
            onChanged: notifier.updatePasswordConfirmation,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // Требования к паролю
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Требования к паролю:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RequirementItem(
                  text: 'Минимум 4 символов',
                  isMet: state.password.length >= 4,
                ),
                // _RequirementItem(
                //   text: 'Заглавные и строчные буквы',
                //   isMet:
                //       state.password.contains(RegExp(r'[A-Z]')) &&
                //       state.password.contains(RegExp(r'[a-z]')),
                // ),
                // _RequirementItem(
                //   text: 'Цифры',
                //   isMet: state.password.contains(RegExp(r'[0-9]')),
                // ),
                // _RequirementItem(
                //   text: 'Специальные символы (!@#\$%^&*)',
                //   isMet: state.password.contains(
                //     RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                //   ),
                // ),
                _RequirementItem(
                  text: 'Пароли совпадают',
                  isMet:
                      state.password.isNotEmpty &&
                      state.password == state.passwordConfirmation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Предупреждение
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ВАЖНО: Запомните или надежно сохраните этот пароль. Восстановление невозможно!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Индикатор сложности пароля
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    final color = _getStrengthColor(context, strength);
    final label = _getStrengthLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 4,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _calculateStrength() {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    if (password.length >= 12) strength++;
    return strength.clamp(0, 4);
  }

  Color _getStrengthColor(BuildContext context, int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Theme.of(context).colorScheme.error;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Слабый';
      case 2:
        return 'Средний';
      case 3:
        return 'Хороший';
      case 4:
        return 'Отличный';
      default:
        return 'Слабый';
    }
  }
}

/// Элемент требования к паролю
class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _RequirementItem({required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isMet
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
