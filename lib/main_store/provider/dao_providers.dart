import 'package:hoplixi/main_store/main_store.dart';

import 'main_store_provider.dart';
import '../dao/index.dart';
import 'package:riverpod/riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';

typedef _DaoFactory<TDao> = TDao Function(MainStore store);

Future<TDao> _ensureDao<TDao>(Ref ref, _DaoFactory<TDao> factory) async {
  final manager = await ref.watch(mainStoreManagerProvider.future);
  final store = manager?.currentStore;
  if (store == null) {
    throw DatabaseError.notInitialized(timestamp: DateTime.now());
  }
  return factory(store);
}

final passwordDaoProvider = FutureProvider<PasswordDao>(
  (ref) => _ensureDao(ref, (store) => PasswordDao(store)),
);

final passwordHistoryDaoProvider = FutureProvider<PasswordHistoryDao>(
  (ref) => _ensureDao(ref, (store) => PasswordHistoryDao(store)),
);

final otpDaoProvider = FutureProvider<OtpDao>(
  (ref) => _ensureDao(ref, (store) => OtpDao(store)),
);

final otpHistoryDaoProvider = FutureProvider<OtpHistoryDao>(
  (ref) => _ensureDao(ref, (store) => OtpHistoryDao(store)),
);

final noteDaoProvider = FutureProvider<NoteDao>(
  (ref) => _ensureDao(ref, (store) => NoteDao(store)),
);

final noteHistoryDaoProvider = FutureProvider<NoteHistoryDao>(
  (ref) => _ensureDao(ref, (store) => NoteHistoryDao(store)),
);

final bankCardDaoProvider = FutureProvider<BankCardDao>(
  (ref) => _ensureDao(ref, (store) => BankCardDao(store)),
);

final bankCardHistoryDaoProvider = FutureProvider<BankCardHistoryDao>(
  (ref) => _ensureDao(ref, (store) => BankCardHistoryDao(store)),
);

final fileDaoProvider = FutureProvider<FileDao>(
  (ref) => _ensureDao(ref, (store) => FileDao(store)),
);

final fileHistoryDaoProvider = FutureProvider<FileHistoryDao>(
  (ref) => _ensureDao(ref, (store) => FileHistoryDao(store)),
);

final categoryDaoProvider = FutureProvider<CategoryDao>(
  (ref) => _ensureDao(ref, (store) => CategoryDao(store)),
);

final iconDaoProvider = FutureProvider<IconDao>(
  (ref) => _ensureDao(ref, (store) => IconDao(store)),
);

// /// DAO провайдер для работы с паролями
// final passwordDaoProvider = FutureProvider<PasswordDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? PasswordDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с историей паролей
// final passwordHistoryDaoProvider = FutureProvider<PasswordHistoryDao?>((
//   ref,
// ) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? PasswordHistoryDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с OTP
// final otpDaoProvider = FutureProvider<OtpDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? OtpDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с историей OTP
// final otpHistoryDaoProvider = FutureProvider<OtpHistoryDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? OtpHistoryDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с заметками
// final noteDaoProvider = FutureProvider<NoteDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? NoteDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с историей заметок
// final noteHistoryDaoProvider = FutureProvider<NoteHistoryDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? NoteHistoryDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с банковскими картами
// final bankCardDaoProvider = FutureProvider<BankCardDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? BankCardDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с историей банковских карт
// final bankCardHistoryDaoProvider = FutureProvider<BankCardHistoryDao?>((
//   ref,
// ) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? BankCardHistoryDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с файлами
// final fileDaoProvider = FutureProvider<FileDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? FileDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с историей файлов
// final fileHistoryDaoProvider = FutureProvider<FileHistoryDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? FileHistoryDao(mainStore!.currentStore!)
//       : null;
// });

// /// DAO провайдер для работы с категориями
// final categoryDaoProvider = FutureProvider<CategoryDao?>((ref) async {
//   final mainStore = await ref.watch(mainStoreManagerProvider.future);
//   return mainStore?.currentStore != null
//       ? CategoryDao(mainStore!.currentStore!)
//       : null;
// });
