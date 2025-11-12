import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Форма для создания и редактирования OTP/2FA
/// TODO: Реализовать полную функциональность формы
class OtpFormScreen extends StatelessWidget {
  final String? otpId;

  const OtpFormScreen({super.key, this.otpId});

  @override
  Widget build(BuildContext context) {
    final isEditMode = otpId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Редактировать OTP' : 'Новый OTP'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Форма OTP/2FA',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO: Реализовать форму создания/редактирования OTP',
              style: TextStyle(color: Colors.grey),
            ),
            if (isEditMode) ...[
              const SizedBox(height: 8),
              Text('OTP ID: $otpId', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
