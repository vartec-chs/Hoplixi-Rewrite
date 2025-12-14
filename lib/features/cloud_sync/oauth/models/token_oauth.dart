// String get accessToken;
//   String get refreshToken;
//   String get userName;
//   String get iss;
//   bool get timeToRefresh;
//   bool get canRefresh;
//   bool get timeToLogin;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_storage_all/cloud_storage_all.dart' show OAuth2Token;

part 'token_oauth.freezed.dart';
part 'token_oauth.g.dart';

@freezed
abstract class TokenOAuth with _$TokenOAuth {
  const factory TokenOAuth({
    required String id,
    required String accessToken,
    required String refreshToken,
    required String userName,
    required String iss,
    required bool timeToRefresh,
    required bool canRefresh,
    required bool timeToLogin,
    required String tokenJson,
  }) = _TokenOAuth;

  // fromJson
  factory TokenOAuth.fromJson(Map<String, dynamic> json) =>
      _$TokenOAuthFromJson(json);
}
