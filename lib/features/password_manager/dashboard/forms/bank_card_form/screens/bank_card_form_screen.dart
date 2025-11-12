import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Форма для создания и редактирования банковской карты
/// TODO: Реализовать полную функциональность формы
class BankCardFormScreen extends StatelessWidget {
  final String? bankCardId;

  const BankCardFormScreen({super.key, this.bankCardId});

  @override
  Widget build(BuildContext context) {
    final isEditMode = bankCardId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Редактировать карту' : 'Новая банковская карта',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Форма банковской карты',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO: Реализовать форму создания/редактирования карты',
              style: TextStyle(color: Colors.grey),
            ),
            if (isEditMode) ...[
              const SizedBox(height: 8),
              Text(
                'Bank Card ID: $bankCardId',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
