import 'package:local_auth/local_auth.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/app_preferences/settings_key.dart';
import 'package:result_dart/result_dart.dart';

class SettingsService {
  final PreferencesService _prefs;
  final SecureStorageService _secureStorage;
  final LocalAuthentication _localAuth;

  SettingsService(this._prefs, this._secureStorage, this._localAuth);

  Future<T> getValue<T>(SettingsKey<T> key) async {
    if (key.isProtected) {
      final secureKey = SecureKey<T>(key.key);
      return await _secureStorage.getOrDefault(secureKey, key.defaultValue);
    } else {
      final prefKey = PrefKey<T>(key.key);
      return _prefs.getOrDefault(prefKey, key.defaultValue);
    }
  }

  Future<AsyncResult<void>> setValue<T>(SettingsKey<T> key, T value) async {
    if (key.useBiometricProtect) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        if (canCheck) {
          final didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Подтвердите изменение настройки ${key.label}',
            options: const AuthenticationOptions(biometricOnly: true),
          );
          if (!didAuthenticate) {
            return const Failure(Exception('Biometric authentication failed'));
          }
        }
      } catch (e) {
        return Failure(e as Exception);
      }
    }

    try {
      if (key.isProtected) {
        final secureKey = SecureKey<T>(key.key);
        await _secureStorage.set(secureKey, value);
      } else {
        final prefKey = PrefKey<T>(key.key);
        await _prefs.set(prefKey, value);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e as Exception);
    }
  }

  Future<AsyncResult<T>> getProtectedValue<T>(SettingsKey<T> key) async {
    if (key.useBiometricProtect) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        if (canCheck) {
          final didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Подтвердите доступ к настройке ${key.label}',
            options: const AuthenticationOptions(biometricOnly: true),
          );
          if (!didAuthenticate) {
            return const Failure(Exception('Biometric authentication failed'));
          }
        }
      } catch (e) {
        return Failure(e as Exception);
      }
    }

    try {
      final val = await getValue(key);
      return Success(val);
    } catch (e) {
      return Failure(e as Exception);
    }
  }
}
