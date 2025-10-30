import 'package:get_it/get_it.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  getIt.registerSingleton<PreferencesService>(await PreferencesService.init());
  getIt.registerSingleton<SecureStorageService>(SecureStorageService.init());
}
