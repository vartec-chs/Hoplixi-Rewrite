import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 900,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Добавить новую категорию
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Управление категориями',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('Категория ${index + 1}'),
                      subtitle: Text('${(index + 1) * 5} записей'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              // Редактировать категорию
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outlined),
                            onPressed: () {
                              // Удалить категорию
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
