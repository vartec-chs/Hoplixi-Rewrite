import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final PreferencesService preferencesService = await PreferencesService.init();
  getIt.registerSingleton<PreferencesService>(preferencesService);
  getIt.registerSingleton<FlutterSecureStorage>(setupSecureStorage());
  getIt.registerSingleton<SecureStorageService>(
    SecureStorageService.init(getIt<FlutterSecureStorage>()),
  );

  // Инициализация HiveBoxManager
  final hiveBoxManager = HiveBoxManager(getIt<FlutterSecureStorage>());
  await hiveBoxManager.initialize();
  getIt.registerSingleton<HiveBoxManager>(hiveBoxManager);

  // Инициализация DatabaseHistoryService
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  getIt.registerSingleton<DatabaseHistoryService>(databaseHistoryService);
}

FlutterSecureStorage setupSecureStorage() {
  return FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    lOptions: const LinuxOptions(),
    wOptions: const WindowsOptions(),
    mOptions: const MacOsOptions(),
    webOptions: const WebOptions(),
  );
}
