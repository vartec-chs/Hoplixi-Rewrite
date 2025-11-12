import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Форма для создания и редактирования заметки
/// TODO: Реализовать полную функциональность формы
class NoteFormScreen extends StatelessWidget {
  final String? noteId;

  const NoteFormScreen({super.key, this.noteId});

  @override
  Widget build(BuildContext context) {
    final isEditMode = noteId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Редактировать заметку' : 'Новая заметка'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Форма заметки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO: Реализовать форму создания/редактирования заметки',
              style: TextStyle(color: Colors.grey),
            ),
            if (isEditMode) ...[
              const SizedBox(height: 8),
              Text('Note ID: $noteId', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
