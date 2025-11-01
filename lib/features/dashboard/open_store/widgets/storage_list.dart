import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/dashboard/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/dashboard/open_store/widgets/storage_card.dart';

/// Список доступных хранилищ
class StorageList extends StatelessWidget {
  final List<StorageInfo> storages;
  final StorageInfo? selectedStorage;
  final void Function(StorageInfo) onStorageSelected;

  const StorageList({
    super.key,
    required this.storages,
    required this.selectedStorage,
    required this.onStorageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (storages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет доступных хранилищ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте новое хранилище или\nимпортируйте существующее',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: screenPadding,
      itemCount: storages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final storage = storages[index];
        final isSelected = selectedStorage?.path == storage.path;

        return StorageCard(
          storage: storage,
          isSelected: isSelected,
          onTap: () => onStorageSelected(storage),
        );
      },
    );
  }
}
