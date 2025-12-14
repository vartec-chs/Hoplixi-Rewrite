import 'dart:convert';

import 'oauth2_rest_body.dart';

class OAuth2FormData {
  final String? name;
  final OAuth2RestBody body;
  final String? filename; // 파일이면 필요
  final String? contentType;

  String? _header;

  String buildHeader({bool contentTypeOnly = false}) {
    return _header ??= _buildHeader(contentTypeOnly);
  }

  String _buildHeader(bool contentTypeOnly) {
    final sb = StringBuffer();
    if (!contentTypeOnly) {
      sb.write('Content-Disposition: form-data; name="$name"');
      if (filename != null) {
        sb.write('; filename="$filename"');
      }
      sb.write('\r\n');
    }

    final type = contentType ?? body.contentType ?? 'application/octet-stream';
    sb.write('Content-Type: $type\r\n');
    return sb.toString();
  }

  OAuth2FormData({
    this.name,
    required this.body,
    this.filename,
    this.contentType,
  });
}

class OAuth2MultiBody implements OAuth2RestBody {
  final List<OAuth2FormData> parts;
  final String boundary;
  final String type; //form-data or related

  OAuth2MultiBody({required this.parts, required this.type, String? boundary})
    : boundary = boundary ?? _generateBoundary();

  static String _generateBoundary() =>
      'boundary-${DateTime.now().millisecondsSinceEpoch}';

  @override
  String? get contentType => 'multipart/$type; boundary=$boundary';

  String buildHeader(OAuth2FormData part) {
    return part.buildHeader(contentTypeOnly: type == "related");
  }

  @override
  int? get contentLength {
    if (parts.any(
      (p) => p.body.contentLength == null || p.body.contentLength! < 0,
    )) {
      return null;
    }

    int total = 0;
    for (final part in parts) {
      total += utf8.encode('--$boundary\r\n').length;
      total += utf8.encode(buildHeader(part)).length;
      total += 2; // \r\n after headers
      total += part.body.contentLength!;
      total += 2; // \r\n after body
    }
    total += utf8.encode('--$boundary--\r\n').length;
    return total;
  }

  @override
  List<int> toBytes() {
    throw UnimplementedError('OAuth2MultipartFormDataBody는 toStream()만 지원합니다.');
  }

  @override
  Stream<List<int>> toStream() async* {
    for (final part in parts) {
      yield utf8.encode('--$boundary\r\n');
      yield utf8.encode(buildHeader(part));
      yield utf8.encode('\r\n');
      yield* part.body.toStream();
      yield utf8.encode('\r\n');
    }
    yield utf8.encode('--$boundary--\r\n');
  }

  factory OAuth2MultiBody.formData(List<OAuth2FormData> parts) {
    return OAuth2MultiBody(parts: parts, type: "form-data");
  }

  factory OAuth2MultiBody.related(OAuth2JsonBody meta, OAuth2FileBody file) {
    var parts = [OAuth2FormData(body: meta), OAuth2FormData(body: file)];
    return OAuth2MultiBody(parts: parts, type: "related");
  }
}
