import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'oauth2_token_storage.dart';

class OAuth2TokenStorageJson implements OAuth2TokenStorage {
  File? _file;

  OAuth2TokenStorageJson({File? file}) {
    _file = file;
  }

  Future<File> getFile() async {
    if (_file != null) return _file!;
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.path}/oauth2_tokens.json');
    return _file!;
  }

  Future<Map<String, String>> _readData() async {
    try {
      final file = _file ?? await getFile();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  Future<void> _writeData(Map<String, String> data) async {
    final file = _file ?? await getFile();
    final content = jsonEncode(data);
    await file.writeAsString(content);
  }

  @override
  Future<String?> load(String key) async {
    final data = await _readData();
    return data[key];
  }

  @override
  Future<void> save(String key, String value) async {
    final data = await _readData();
    data[key] = value;
    await _writeData(data);
  }

  @override
  Future<void> delete(String key) async {
    final data = await _readData();
    data.remove(key);
    await _writeData(data);
  }

  @override
  Future<Map<String, String>> loadAll({String? keyPrefix}) async {
    final data = await _readData();
    if (keyPrefix == null || keyPrefix.isEmpty) return data;
    return Map.fromEntries(
      data.entries.where((entry) => entry.key.startsWith(keyPrefix)),
    );
  }
}
