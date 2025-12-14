import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../exception/oauth2_exception.dart';
import '../oauth2_cancel_token.dart';

abstract interface class OAuth2RestResponse {
  int? get statusCode;
  String? headerValue(String header);
  void ensureSuccess();
  bool get isSuccess;

  Stream<List<int>> get bodyStream;
  Future<String> readAsString();
  Future<List<int>> readAsBytes();

  Future<void> copyTo(
    StreamSink<List<int>> sink, {
    void Function(int uploadedBytes, int? totalBytes)? onProgress,
    OAuth2CancelToken? token,
  });

  Future<void> dispose();
}

class OAuth2RestResponseF implements OAuth2RestResponse {
  final HttpClientResponse? _response;
  final Stream<List<int>>? _wrappedStream;
  final int _statusCode;
  final HttpHeaders? _headers;
  bool _disposed = false;

  OAuth2RestResponseF(HttpClientResponse response)
    : _response = response,
      _wrappedStream = null,
      _statusCode = response.statusCode,
      _headers = response.headers;

  OAuth2RestResponseF.fromStream(
    Stream<List<int>> stream,
    int statusCode,
    HttpHeaders headers,
  ) : _response = null,
      _wrappedStream = stream,
      _statusCode = statusCode,
      _headers = headers;

  @override
  bool get isSuccess => _statusCode >= 200 && _statusCode < 300;

  @override
  void ensureSuccess() {
    if (!isSuccess) {
      throw HttpException('HTTP request failed, statusCode=$statusCode');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('Response already disposed.');
    }
  }

  @override
  int get statusCode => _statusCode;

  @override
  Stream<List<int>> get bodyStream {
    _ensureNotDisposed();
    return _wrappedStream ?? _response!;
  }

  @override
  Future<String> readAsString() async {
    _ensureNotDisposed();
    final body = await utf8.decodeStream(bodyStream);
    await dispose();
    return body;
  }

  @override
  Future<List<int>> readAsBytes() async {
    _ensureNotDisposed();

    final chunks = await bodyStream.toList(); // List<List<int>>
    final body = <int>[];
    for (final chunk in chunks) {
      body.addAll(chunk);
    }
    await dispose();
    return body;
  }

  @override
  Future<void> copyTo(
    StreamSink<List<int>> sink, {
    void Function(int uploadedBytes, int? totalBytes)? onProgress,
    OAuth2CancelToken? token,
  }) async {
    _ensureNotDisposed();
    if (onProgress != null) {
      int downloaded = 0;
      int? totalLength = int.tryParse(headerValue("Content-Length") ?? "");
      await for (final chunk in bodyStream) {
        if (token?.isCancelled ?? false) {
          throw OAuth2ExceptionF.canceled(
            message: token?.reason ?? 'Cancelled by user',
          );
        }
        sink.add(chunk);

        downloaded += chunk.length;
        onProgress.call(downloaded, totalLength);
      }
    } else {
      await bodyStream.pipe(sink);
    }
    await dispose();
  }

  @override
  Future<void> dispose() async {
    if (!_disposed) {
      if (_response != null) {
        try {
          await _response.drain();
        } catch (_) {
          // игнорируем
        }
      } else if (_wrappedStream != null) {
        try {
          await _wrappedStream.drain();
        } catch (_) {
          // игнорируем
        }
      }
      _disposed = true;
    }
  }

  @override
  String? headerValue(String header) => _headers?.value(header);
}
