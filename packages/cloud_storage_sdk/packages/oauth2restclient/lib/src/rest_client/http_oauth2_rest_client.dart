import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../exception/oauth2_exception.dart';
import '../oauth2_cancel_token.dart';
import 'http_method.dart';
import 'oauth2_rest_body.dart';
import 'oauth2_rest_client.dart';
import 'oauth2_rest_response.dart';

class HttpOAuth2RestClient implements OAuth2RestClient {
  final _client = HttpClient();

  String? accessToken;
  final Future<String?> Function()? refreshToken;

  String authScheme;
  bool _triedOAuth = false;

  HttpOAuth2RestClient({
    this.accessToken,
    this.refreshToken,
    this.authScheme = "Bearer",
  });

  Map<String, String> _combineHeader(
    Map<String, String>? original,
    Map<String, String?> additions,
  ) {
    final result = {...?original};

    for (var entry in additions.entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value!;
      }
    }

    return result;
  }

  Uri _buildUri(String url, Map<String, String>? queryParams) {
    final parsed = Uri.parse(url);
    if (queryParams?.isEmpty ?? true) return parsed;

    final mergedQuery = {...parsed.queryParameters, ...?queryParams};
    return parsed.replace(queryParameters: mergedQuery);
  }

  Future<OAuth2RestResponse> _request(
    HttpMethod method,
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onUploadProgress,
    OAuth2ProgressCallback? onDownloadProgress,
    OAuth2CancelToken? token,
    required int retryCount,
  }) async {
    final lastHeaders = _combineHeader(headers, {
      "Authorization": "$authScheme $accessToken",
      "Content-Type": body?.contentType,
      "Content-Length": body?.contentLength?.toString(),
    });

    final uri = _buildUri(url, queryParams);

    final request = await _client.openUrl(method.name.toUpperCase(), uri);

    lastHeaders.forEach((key, value) => request.headers.set(key, value));

    if (body != null) {
      final stream = _wrapUploadStream(
        body.toStream(),
        body.contentLength,
        onProgress: onUploadProgress,
        token: token,
        request: request,
      );

      await request.addStream(stream);
    }

    HttpClientResponse response = await request.close();

    if (response.statusCode == 401 && retryCount < 3 && refreshToken != null) {
      var newToken = await refreshToken!();
      if (newToken?.isNotEmpty ?? false) {
        try {
          await response.drain();
        } catch (_) {}

        accessToken = newToken;
        return _request(
          method,
          url,
          body: body,
          queryParams: queryParams,
          headers: headers,
          onUploadProgress: onUploadProgress,
          onDownloadProgress: onDownloadProgress,
          token: token,
          retryCount: retryCount + 1,
        );
      } else if (!_triedOAuth && authScheme == "Bearer") {
        _triedOAuth = true;
        authScheme = "OAuth";
        try {
          await response.drain();
        } catch (_) {}
        return _request(
          method,
          url,
          body: body,
          queryParams: queryParams,
          headers: headers,
          onUploadProgress: onUploadProgress,
          onDownloadProgress: onDownloadProgress,
          token: token,
          retryCount: retryCount,
        );
      } else {
        throw OAuth2ExceptionF.unauthorized(message: 'Failed to refresh token');
      }
    }

    // Оборачиваем response для отслеживания прогресса скачивания
    if (onDownloadProgress != null) {
      final wrappedStream = _wrapDownloadStream(
        response,
        response.contentLength,
        onProgress: onDownloadProgress,
        token: token,
      );
      return OAuth2RestResponseF.fromStream(
        wrappedStream,
        response.statusCode,
        response.headers,
      );
    }

    return OAuth2RestResponseF(response);
  }

  @override
  Future<OAuth2RestResponse> get(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  }) {
    return _request(
      HttpMethod.get,
      url,
      queryParams: queryParams,
      headers: headers,
      onDownloadProgress: onProgress,
      retryCount: 0,
    );
  }

  Future<String> _consumeString(OAuth2RestResponse response) async {
    try {
      if (kDebugMode) {
        var str = await response.readAsString();
        //debugPrint(str);
        response.ensureSuccess();
        return str;
      } else {
        response.ensureSuccess();
        return await response.readAsString();
      }
    } finally {
      response.dispose();
    }
  }

  @override
  Future<String> getString(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  }) async {
    var response = await get(
      url,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
    );
    return await _consumeString(response);
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  }) async {
    var jsonString = await getString(
      url,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
    );
    var json = jsonDecode(jsonString);
    return json as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getJsonList(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  }) async {
    var jsonString = await getString(
      url,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
    );
    var json = jsonDecode(jsonString);
    return json as List<Map<String, dynamic>>;
  }

  @override
  Future<Stream<List<int>>> getStream(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  }) async {
    var response = await get(
      url,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
    );
    response.ensureSuccess();
    return response.bodyStream;
  }

  @override
  Future<void> delete(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    var response = await _request(
      HttpMethod.delete,
      url,
      queryParams: queryParams,
      headers: headers,
      retryCount: 0,
    );
    try {
      response.ensureSuccess();
    } finally {
      response.dispose();
    }
  }

  @override
  Future<OAuth2RestResponse> put(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) {
    return _request(
      HttpMethod.put,
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onUploadProgress: onProgress,
      token: token,
      retryCount: 0,
    );
  }

  @override
  Future<String> putString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await put(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
      token: token,
    );
    return _consumeString(response);
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await putString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> putJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await putString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as List<Map<String, dynamic>>;
  }

  @override
  Future<Stream<List<int>>> putStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await put(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    response.ensureSuccess();
    return response.bodyStream;
  }

  Stream<List<int>> _wrapUploadStream(
    Stream<List<int>> original,
    int? totalLength, {
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
    required HttpClientRequest request,
  }) async* {
    int uploaded = 0;

    await for (final chunk in original) {
      // ✅ 취소 처리
      if (token?.isCancelled == true) {
        try {
          request.abort();
        } catch (_) {
          // 무시 (abort 실패는 괜찮음)
        }
        throw OAuth2ExceptionF.canceled(
          reason: token?.reason,
          message: 'Upload cancelled',
        );
      }

      uploaded += chunk.length;

      // ✅ 전송률(progress) 콜백 호출
      onProgress?.call(uploaded, totalLength);

      yield chunk; // 실제 전송
    }
  }

  Stream<List<int>> _wrapDownloadStream(
    Stream<List<int>> original,
    int? totalLength, {
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async* {
    int downloaded = 0;

    await for (final chunk in original) {
      // Проверка отмены
      if (token?.isCancelled == true) {
        throw OAuth2ExceptionF.canceled(
          reason: token?.reason,
          message: 'Download cancelled',
        );
      }

      downloaded += chunk.length;

      // Вызов колбэка прогресса
      onProgress?.call(downloaded, totalLength);

      yield chunk;
    }
  }

  @override
  Future<OAuth2RestResponse> post(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) {
    return _request(
      HttpMethod.post,
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onUploadProgress: onProgress,
      token: token,
      retryCount: 0,
    );
  }

  @override
  Future<String> postString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await post(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
      token: token,
    );
    return _consumeString(response);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await postString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> postJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await postString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as List<Map<String, dynamic>>;
  }

  @override
  Future<Stream<List<int>>> postStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await post(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    response.ensureSuccess();
    return response.bodyStream;
  }

  @override
  Future<OAuth2RestResponse> patch(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    return _request(
      HttpMethod.patch,
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onUploadProgress: onProgress,
      token: token,
      retryCount: 0,
    );
  }

  @override
  Future<String> patchString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await patch(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
      onProgress: onProgress,
      token: token,
    );
    return await _consumeString(response);
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await patchString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> patchJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var jsonString = await patchString(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    var json = jsonDecode(jsonString);
    return json as List<Map<String, dynamic>>;
  }

  @override
  Future<Stream<List<int>>> patchStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  }) async {
    var response = await patch(
      url,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
    response.ensureSuccess();
    return response.bodyStream;
  }
}
