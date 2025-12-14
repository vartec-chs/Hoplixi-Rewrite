import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PKCE {
  /// RFC 7636에 따라 code_verifier는 43~128자 사이여야 합니다.
  static String generateCodeVerifier({int length = 64}) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Base64 URL-safe 인코딩 (padding 제거, +→-, /→_)
  static String base64UrlEncodeNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// code_challenge = BASE64URL-ENCODE(SHA256(code_verifier))
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = ascii.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncodeNoPadding(digest.bytes);
  }
}
