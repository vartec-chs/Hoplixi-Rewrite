import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Форма для создания и редактирования файла
/// TODO: Реализовать полную функциональность формы с загрузкой файлов
class FileFormScreen extends StatelessWidget {
  final String? fileId;

  const FileFormScreen({super.key, this.fileId});

  @override
  Widget build(BuildContext context) {
    final isEditMode = fileId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Редактировать файл' : 'Загрузить файл'),
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
              Icons.attach_file_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Форма загрузки файла',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO: Реализовать форму загрузки/редактирования файла',
              style: TextStyle(color: Colors.grey),
            ),
            if (isEditMode) ...[
              const SizedBox(height: 8),
              Text('File ID: $fileId', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
