import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../token/oauth2_token.dart';
import 'pkce.dart';

HttpServer? _server;
StreamSubscription? _linkSubscription;

abstract interface class OAuth2Provider {
  String get name;
  String get authScheme;
  Future<OAuth2Token?> login({void Function(String error)? onError});
  void cancelLogin();
  Future<String?> exchangeCode(String? code);
  Future<OAuth2Token?> refreshToken(String? refreshToken);
  Future<Map<String, dynamic>?> getUserInfo(String accessToken);
}

class OAuth2ProviderF implements OAuth2Provider {
  final String clientId;
  final String? clientSecret;
  final String redirectUri;
  final List<String>? scopes;
  final String authEndpoint;
  final String tokenEndpoint;
  final String getUserInfoEndpoint;
  final bool isUsePostCallUserInfo;

  @override
  final String authScheme;

  String? codeVerifier;
  bool _isCancelled = false;
  void Function(String error)? _onError;

  @override
  final String name;

  OAuth2ProviderF({
    required this.name,
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
    this.scopes,
    required this.authEndpoint,
    required this.tokenEndpoint,
    required this.getUserInfoEndpoint,
    this.isUsePostCallUserInfo = false,
    this.authScheme = 'Bearer',
  });

  String get _authUrl {
    codeVerifier ??= PKCE.generateCodeVerifier();
    var cc = PKCE.generateCodeChallenge(codeVerifier!);

    return "$authEndpoint"
        "?client_id=$clientId"
        "&redirect_uri=$redirectUri"
        "&response_type=code"
        "${scopes != null ? "&scope=${scopes!.join('%20')}" : ""}"
        "&access_type=offline"
        "&token_access_type=offline"
        "&prompt=consent"
        "&code_challenge_method=S256"
        "&code_challenge=$cc";
  }

  @override
  Future<OAuth2Token?> login({void Function(String error)? onError}) async {
    _isCancelled = false;
    _onError = onError;
    if (Platform.isAndroid || Platform.isIOS) return loginFromMobile();
    return loginFromDesktop();
  }

  @override
  void cancelLogin() {
    _isCancelled = true;
    _server?.close();
    _server = null;
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _onError?.call('Login cancelled by user');
    _onError = null;
  }

  Future<OAuth2Token?> loginFromDesktop() async {
    try {
      if (_isCancelled) {
        return null;
      }

      var uri = Uri.parse(_authUrl);
      await launchUrl(uri); // ✅ 자동으로 브라우저 실행

      final bindUri = Uri.parse(redirectUri);
      final host = bindUri.host; // 'localhost'
      final port = bindUri.port; // 8080 (또는 지정된 포트)
      final path = bindUri.path; // '/ca

      await _server?.close();
      _server = await HttpServer.bind(host, port);

      await for (final request in _server!) {
        if (_isCancelled) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          await request.response.close();
          break;
        }

        // callback 경로 확인
        if (request.uri.path == path) {
          // 코드 파라미터 추출
          var code = request.uri.queryParameters['code'];
          final response = await exchangeCode(code);

          if (response == null) {
            _onError?.call('Failed to exchange authorization code');
            request.response.headers.contentType = ContentType.html;
            request.response.write('''
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Login Failed</title>
                <style>
                  body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #ff9a9e, #fecfef);
                    color: #333;
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    text-align: center;
                  }
                  .container {
                    background: rgba(255, 255, 255, 0.9);
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
                    max-width: 400px;
                    width: 90%;
                  }
                  h1 {
                    color: #e74c3c;
                    font-size: 2.5em;
                    margin-bottom: 20px;
                    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
                  }
                  p {
                    font-size: 1.2em;
                    margin-bottom: 30px;
                  }
                  .icon {
                    font-size: 4em;
                    margin-bottom: 20px;
                  }
                  .btn {
                    background: #e74c3c;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 8px;
                    font-size: 1em;
                    cursor: pointer;
                    text-decoration: none;
                    display: inline-block;
                  }
                  .btn:hover {
                    background: #c0392b;
                  }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="icon">❌</div>
                  <h1>Login Failed</h1>
                  <p>Authentication failed. Please close this window and return to the app.</p>
               
                </div>
              </body>
              </html>
            ''');
            await request.response.close();
          } else {
            // 성공 메시지를 브라우저에 표시
            request.response.headers.contentType = ContentType.html;
            request.response.write('''
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Login Success</title>
                <style>
                  body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    background: linear-gradient(135deg, #a8edea, #fed6e3);
                    color: #333;
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    text-align: center;
                  }
                  .container {
                    background: rgba(255, 255, 255, 0.9);
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
                    max-width: 400px;
                    width: 90%;
                  }
                  h1 {
                    color: #27ae60;
                    font-size: 2.5em;
                    margin-bottom: 20px;
                    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
                  }
                  p {
                    font-size: 1.2em;
                    margin-bottom: 30px;
                  }
                  .icon {
                    font-size: 4em;
                    margin-bottom: 20px;
                  }
                  .btn {
                    background: #27ae60;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 8px;
                    font-size: 1em;
                    cursor: pointer;
                    text-decoration: none;
                    display: inline-block;
                  }
                  .btn:hover {
                    background: #229954;
                  }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="icon">✅</div>
                  <h1>Login Success!</h1>
                  <p>Authentication completed. Please close this window and return to the app.</p>
               
                </div>
              </body>
              </html>
            ''');
            await request.response.close();

            debugPrint("OAuth2 login successful. Data: $response");

            return OAuth2TokenF.fromJsonString(response);
          }
        } else {
          // 잘못된 경로 처리
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!_isCancelled) {
        _onError?.call('Login error: ${e.toString()}');
      }
    } finally {
      await _server?.close();
      _server = null;
    }

    return null;
  }

  Future<OAuth2Token?> loginFromMobile() async {
    try {
      if (_isCancelled) {
        return null;
      }

      var uri = Uri.parse(_authUrl);
      if (!await canLaunchUrl(uri)) {
        _onError?.call('Cannot launch browser for authentication');
        return null;
      }

      Completer<String?> completer = Completer();
      final appLinks = AppLinks(); // AppLinks is singleton
      _linkSubscription = appLinks.uriLinkStream.listen((uri) async {
        if (_isCancelled) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }

        String? response;
        var code = uri.queryParameters["code"];
        try {
          response = await exchangeCode(code);
          if (response == null) {
            _onError?.call('Failed to exchange authorization code');
          }
        } catch (e) {
          _onError?.call('Exchange code error: ${e.toString()}');
        } finally {
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }
      });

      await launchUrl(uri); // ✅ 자동으로 브라우저 실행
      var response = await completer.future;
      _linkSubscription?.cancel();
      _linkSubscription = null;
      closeInAppWebView();

      if (_isCancelled) {
        return null;
      }

      if (response == null) return null;

      return OAuth2TokenF.fromJsonString(response);
    } catch (e) {
      debugPrint('loginFromMobile error: $e');
      if (!_isCancelled) {
        _onError?.call('Login error: ${e.toString()}');
      }
      return null;
    }
  }

  @override
  Future<String?> exchangeCode(String? code) async {
    if (code == null) return null;

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "client_id": clientId,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": redirectUri,
        if (clientSecret != null) "client_secret": clientSecret,
        if (codeVerifier != null) "code_verifier": codeVerifier,
      },
    );

    if (response.statusCode == 200) return response.body;
    return null;
  }

  @override
  Future<OAuth2Token?> refreshToken(String? refreshToken) async {
    if (refreshToken?.isEmpty ?? true) return null;

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "client_id": clientId,
        if (clientSecret != null) "client_secret": clientSecret,
        "grant_type": "refresh_token",
        "refresh_token": refreshToken,
      },
    );

    if (response.statusCode == 200) {
      return OAuth2TokenF.fromJsonString(response.body);
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    if (accessToken.isEmpty) return null;

    try {
      late http.Response response;
      if (isUsePostCallUserInfo) {
        response = await http.post(
          Uri.parse(getUserInfoEndpoint),
          headers: {
            "Authorization": "Bearer $accessToken",
            // "Content-Type": "application/json",
          },
        );
      } else {
        response = await http.get(
          Uri.parse(getUserInfoEndpoint),
          headers: {
            "Authorization": "Bearer $accessToken",
            // "Content-Type": "application/json",
          },
        );
      }

      debugPrint(
        "getUserInfo status: ${response.statusCode} body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("getUserInfo response: $decoded");
        return decoded is Map<String, dynamic> ? decoded : null;
      }
    } catch (e) {
      debugPrint("getUserInfo error: $e");
    }

    return null;
  }
}
