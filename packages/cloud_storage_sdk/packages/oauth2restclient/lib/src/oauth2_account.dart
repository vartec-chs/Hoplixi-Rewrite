import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:oauth2restclient/src/rest_client/oauth2_rest_client.dart';

import 'provider/oauth2_provider.dart';
import 'rest_client/http_oauth2_rest_client.dart';
import 'token/oauth2_token.dart';
import 'token/oauth2_token_storage.dart';

class OAuth2Account {
  final String appPrefix;

  final Map<String, OAuth2Provider> _providers = {};

  void addProvider(OAuth2Provider provider) {
    _providers[provider.name] = provider;
  }

  OAuth2Provider? getProvider(String nameOrIss) {
    for (var name in _providers.keys) {
      if (nameOrIss.contains(name)) {
        return _providers[name];
      }
    }
    return null;
  }

  late final OAuth2TokenStorage _tokenStorage;

  OAuth2Account({OAuth2TokenStorage? tokenStorage, required this.appPrefix}) {
    if (Platform.isAndroid || Platform.isIOS) {
      _tokenStorage = tokenStorage ?? OAuth2TokenStorageSecure();
    } else {
      _tokenStorage = tokenStorage ?? OAuth2TokenStorageShared();
    }
  }

  static const tokenPrefix = "OAUTH2ACCOUNT"; // ✅ OAuth token prefix

  String keyFor(String service, String userName) =>
      "$appPrefix-$tokenPrefix-$service-$userName";

  Future<void> saveAccount(
    String service,
    String userName,
    OAuth2Token token,
  ) async {
    var key = keyFor(service, userName);
    var value = token.toJsonString();
    _tokenStorage.save(key, value);
  }

  Future<List<(String, String)>> allAccounts({String service = ""}) async {
    var prefix = service.isEmpty
        ? "$appPrefix-$tokenPrefix-"
        : keyFor(service, "");
    final all = await _tokenStorage.loadAll(keyPrefix: prefix);

    return all.keys
        .map((key) {
          final parts = key.split("-");
          if (parts.length < 4) return null;
          return (parts[2], parts.sublist(3).join("-"));
        })
        .whereType<(String, String)>()
        .where(
          (tuple) => service.isEmpty || tuple.$1.contains(service),
        ) // ✅  Проверка на совпадение сервиса
        .toList();
  }

  Future<OAuth2Token?> loadAccount(String service, String userName) async {
    var key = keyFor(service, userName);
    var jsonString = await _tokenStorage.load(key);
    if (jsonString == null) return null;
    return OAuth2TokenF.fromJsonString(jsonString);
  }

  Future<void> deleteAccount(String service, String userName) async {
    var key = keyFor(service, userName);
    await _tokenStorage.delete(key);
  }

  Future<OAuth2Token?> any({String service = ""}) async {
    var all = await allAccounts(service: service);
    if (all.isEmpty) return null;
    var first = all.first;
    return loadAccount(first.$1, first.$2);
  }

  /// Новый вход пользователя
  Future<OAuth2Token?> newLogin(
    String service, {
    void Function(String error)? onError,
  }) async {
    var provider = getProvider(service);
    if (provider == null) throw Exception("can't find provider '$service'");

    var token = await provider.login(onError: onError);
    if (token != null) {
      token.provider = service;

      // Получаем информацию о пользователе через API
      final userInfo = await provider.getUserInfo(token.accessToken);
      debugPrint("User info: $userInfo");
      if (userInfo == null) {
        throw Exception("can't get user info from provider");
      }

      token.setUserInfo(userInfo);
      await saveAccount(service, token.userName, token);
    }
    return token;
  }

  /// Автоматический вход, если токен истек, выполняется повторный вход
  Future<OAuth2Token?> tryAutoLogin(
    String service,
    String userName, {
    void Function(String error)? onError,
  }) async {
    var token = await loadAccount(service, userName);
    if (token?.timeToLogin ?? false) {
      token = await forceRelogin(token!, onError: onError);
    }
    return token;
  }

  Future<OAuth2Token?> forceRelogin(
    OAuth2Token expiredToken, {
    void Function(String error)? onError,
  }) async {
    var provider = getProvider(expiredToken.provider);
    if (provider == null) {
      throw Exception("can't find provider for '{$expiredToken.provider}'");
    }

    var token = await provider.login(onError: onError);
    if (token != null) {
      token.provider = provider.name;

      // Получаем информацию о пользователе через API
      final userInfo = await provider.getUserInfo(token.accessToken);
      if (userInfo == null) {
        throw Exception("can't get user info from provider");
      }

      token.setUserInfo(userInfo);
      await saveAccount(provider.name, token.userName, token);
      return token;
    }
    return null;
  }

  Future<OAuth2RestClient> createClient(
    OAuth2Token token, {
    String? authScheme,
  }) async {
    final provider = getProvider(token.provider);
    var client = HttpOAuth2RestClient(
      accessToken: token.accessToken,
      authScheme: authScheme ?? provider?.authScheme ?? "Bearer",
      refreshToken: () async {
        try {
          var newToken = await refreshToken(token);
          return newToken?.accessToken;
        } catch (e) {
          debugPrint(e.toString());
          return null;
        }
      },
    );
    return client;
  }

  final Map<String, Future<OAuth2Token?>> _pendingRefreshes = {};

  Future<OAuth2Token?> refreshToken(OAuth2Token expiredToken) async {
    //, String service, String userName
    final String refreshKey =
        "${expiredToken.provider}:${expiredToken.userName}";

    // Проверьте, выполняется ли уже обновление.
    if (_pendingRefreshes.containsKey(refreshKey)) {
      return _pendingRefreshes[refreshKey];
    }

    // Создайте новую задачу обновления.
    final refreshOperation = _doRefreshToken(expiredToken);

    // Добавьте задачу в список выполняемых.
    _pendingRefreshes[refreshKey] = refreshOperation;

    // После завершения удаления задачи из списка.
    refreshOperation.whenComplete(() {
      _pendingRefreshes.remove(refreshKey);
    });

    return refreshOperation;
  }

  Future<OAuth2Token?> _doRefreshToken(OAuth2Token token) async {
    var provider = getProvider(token.provider);
    if (provider == null) return null;

    //String service, String userName
    var savedToken = await loadAccount(provider.name, token.userName);
    if (savedToken == null) return null;

    var newToken = await provider.refreshToken(savedToken.refreshToken);
    if (newToken == null) return null;

    var mergedToken = savedToken.mergeToken(newToken);

    await saveAccount(provider.name, mergedToken.userName, mergedToken);
    return mergedToken;
  }
}
