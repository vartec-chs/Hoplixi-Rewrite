import 'dart:async';

import '../oauth2_cancel_token.dart';
import 'oauth2_rest_body.dart';
import 'oauth2_rest_response.dart';

typedef OAuth2ProgressCallback =
    void Function(int uploadedBytes, int? totalBytes);

abstract interface class OAuth2RestClient {
  Future<OAuth2RestResponse> get(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  });
  Future<String> getString(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  });
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  });
  Future<List<Map<String, dynamic>>> getJsonList(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  });
  Future<Stream<List<int>>> getStream(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
  });

  Future<OAuth2RestResponse> post(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<String> postString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Map<String, dynamic>> postJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<List<Map<String, dynamic>>> postJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Stream<List<int>>> postStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });

  Future<void> delete(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  });

  Future<OAuth2RestResponse> put(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<String> putString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Map<String, dynamic>> putJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<List<Map<String, dynamic>>> putJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Stream<List<int>>> putStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });

  Future<OAuth2RestResponse> patch(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<String> patchString(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Map<String, dynamic>> patchJson(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<List<Map<String, dynamic>>> patchJsonList(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
  Future<Stream<List<int>>> patchStream(
    String url, {
    OAuth2RestBody? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    OAuth2ProgressCallback? onProgress,
    OAuth2CancelToken? token,
  });
}
