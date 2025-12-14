import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OAuth2TokenStorage {
  Future<String?> load(String key);
  Future<void> save(String key, String value);
  Future<void> delete(String key);
  Future<Map<String, String>> loadAll({String? keyPrefix});
}

class OAuth2TokenStorageShared implements OAuth2TokenStorage {
  SharedPreferences? _storage;

  Future<SharedPreferences> getStorage() async {
    return _storage ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> load(String key) async {
    var storage = await getStorage();
    return storage.getString(key);
  }

  @override
  Future<void> save(String key, String value) async {
    var storage = await getStorage();
    await storage.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    var storage = await getStorage();
    await storage.remove(key);
  }

  @override
  Future<Map<String, String>> loadAll({String? keyPrefix}) async {
    var storage = await getStorage();

    // SharedPreferences에서는 모든 키를 가져오고 필터링해야 함
    final allKeys = storage.getKeys();
    final Map<String, String> result = {};

    for (final key in allKeys) {
      if (key.startsWith(keyPrefix ?? "")) {
        final value = storage.get(key);
        if (value is String) {
          result[key] = value;
        }
      }
    }

    return result;
  }
}

class OAuth2TokenStorageSecure implements OAuth2TokenStorage {
  FlutterSecureStorage? __storage;
  FlutterSecureStorage get _storage {
    return __storage ??= FlutterSecureStorage();
  }

  @override
  Future<String?> load(String key) => _storage.read(key: key);

  @override
  Future<void> save(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Map<String, String>> loadAll({String? keyPrefix}) async {
    var all = await _storage.readAll();

    final allKeys = all.keys;

    final Map<String, String> result = {};

    for (final key in allKeys) {
      if (key.startsWith(keyPrefix ?? "")) {
        final value = all[key];
        if (value != null) {
          result[key] = value;
        }
      }
    }
    return result;
  }
}
