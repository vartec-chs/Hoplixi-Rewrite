import 'dart:convert';

abstract interface class OAuth2Token {
  String get accessToken;
  String get refreshToken;
  String get userName;
  String get iss;
  String get provider;
  set provider(String value);
  bool get timeToRefresh;
  bool get canRefresh;
  bool get timeToLogin;
  String toJsonString();
  OAuth2Token mergeToken(OAuth2Token newToken);
  void setUserInfo(Map<String, dynamic> userInfo);
}

class OAuth2TokenF implements OAuth2Token {
  final Map<String, dynamic> json;
  Map<String, dynamic>? _idToken;

  Map<String, dynamic>? get idToken {
    return _idToken ??= _tryDecodeIdToken(json["id_token"]);
  }

  OAuth2TokenF(this.json) {
    _parseToken(json);
  }

  void _parseToken(Map<String, dynamic> json) {
    if (!json.containsKey("expiry")) {
      if (json.containsKey("expires_in")) {
        json["expiry"] = DateTime.now()
            .toUtc()
            .add(Duration(seconds: json["expires_in"]))
            .subtract(Duration(minutes: 5))
            .toIso8601String();
      } else {
        json["expiry"] = "9999-12-31T23:59:59.999Z";
      }
    }

    if (!json.containsKey("refresh_token_expiry")) {
      if (json.containsKey("refresh_token_expires_in")) {
        json["refresh_token_expiry"] = DateTime.now()
            .toUtc()
            .add(Duration(seconds: json["refresh_token_expires_in"]))
            .subtract(Duration(minutes: 5))
            .toIso8601String();
      } else {
        json["refresh_token_expiry"] = DateTime.now()
            .toUtc()
            .add(Duration(days: 7))
            .toIso8601String();
      }
    }
  }

  Map<String, dynamic> _tryDecodeIdToken(String? idToken) {
    if (idToken?.isEmpty ?? true) return {};

    final parts = idToken!.split('.');
    if (parts.length != 3) {
      return {};
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return jsonDecode(payload);
  }

  DateTime? _expiry;
  DateTime get expiry {
    return _expiry ??= DateTime.parse(json["expiry"]);
  }

  DateTime? _refreshTokenExpiry;
  DateTime get refreshTokenExpiry {
    return _refreshTokenExpiry ??= DateTime.parse(json["refresh_token_expiry"]);
  }

  @override
  bool get timeToRefresh {
    var now = DateTime.now().toUtc();
    return now.isAfter(expiry);
  }

  @override
  bool get canRefresh {
    if (refreshToken.isEmpty) return false;
    var now = DateTime.now().toUtc();
    return now.isBefore(refreshTokenExpiry.subtract(Duration(minutes: 5)));
  }

  @override
  bool get timeToLogin {
    return timeToRefresh && !canRefresh;
  }

  factory OAuth2TokenF.fromJsonString(String jsonResponse) {
    final jsonMap = jsonDecode(jsonResponse);
    return OAuth2TokenF(jsonMap);
  }

  @override
  String toJsonString() {
    return jsonEncode(json);
  }

  @override
  String get accessToken => json["access_token"] ?? "";

  @override
  String get refreshToken => json["refresh_token"] ?? "";

  @override
  String get iss => idToken?["iss"] ?? "";

  @override
  String get provider => json["provider"] ?? iss;

  @override
  set provider(String value) => json["provider"] = value;

  @override
  String get userName {
    // Сначала проверяем user_info, потом idToken
    final userInfo = json["user_info"];
    if (userInfo is Map<String, dynamic>) {
      // Проверяем различные поля, которые могут содержать имя пользователя
      return userInfo["email"] ??
          userInfo["mail"] ??
          userInfo["userPrincipalName"] ??
          userInfo["preferred_username"] ??
          userInfo["login"] ??
          userInfo["sub"] ??
          userInfo["id"] ??
          userInfo["uid"] ??
          "";
    }

    // Если user_info нет, используем idToken
    return idToken?["email"] ?? idToken?["sub"] ?? "";
  }

  @override
  void setUserInfo(Map<String, dynamic> userInfo) {
    json["user_info"] = userInfo;
  }

  @override
  OAuth2Token mergeToken(OAuth2Token newToken) {
    var jsonString = newToken.toJsonString();
    var newJson = jsonDecode(jsonString);
    Map<String, dynamic> mergedToken = {
      ...json, // 기존 값 유지
      ...newJson, // 새로운 값 덮어쓰기
    };

    return OAuth2TokenF(mergedToken);
  }
}
