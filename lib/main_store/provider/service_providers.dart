import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/main_store/services/file_storage_service.dart';

/// Провайдер для FileStorageService
final fileStorageServiceProvider = FutureProvider<FileStorageService>((
  ref,
) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null || manager == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }

  final attachmentsPathResult = await manager.getAttachmentsPath();
  final attachmentsPath = attachmentsPathResult.getOrThrow();

  return FileStorageService(store, attachmentsPath);
});
