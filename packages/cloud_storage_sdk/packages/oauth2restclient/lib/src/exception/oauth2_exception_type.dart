enum OAuth2ExceptionType {
  invalidRequest,
  invalidClient,
  invalidGrant,
  unauthorizedClient,
  unsupportedGrantType,
  invalidScope,
  accessDenied,
  serverError,
  temporarilyUnavailable,
  unauthorized,
  canceled, // 취소 타입 추가
  connectionError,
  unknown;

  // Enum 값을 문자열로 변환 (OAuth2 표준에 맞춤)
  String toStringValue() {
    switch (this) {
      case OAuth2ExceptionType.invalidRequest:
        return 'invalid_request';
      case OAuth2ExceptionType.invalidClient:
        return 'invalid_client';
      case OAuth2ExceptionType.invalidGrant:
        return 'invalid_grant';
      case OAuth2ExceptionType.unauthorizedClient:
        return 'unauthorized_client';
      case OAuth2ExceptionType.unsupportedGrantType:
        return 'unsupported_grant_type';
      case OAuth2ExceptionType.invalidScope:
        return 'invalid_scope';
      case OAuth2ExceptionType.accessDenied:
        return 'access_denied';
      case OAuth2ExceptionType.serverError:
        return 'server_error';
      case OAuth2ExceptionType.temporarilyUnavailable:
        return 'temporarily_unavailable';
      case OAuth2ExceptionType.unauthorized:
        return 'unauthorized';
      case OAuth2ExceptionType.canceled:
        return 'canceled'; // 문자열 값 추가
      case OAuth2ExceptionType.connectionError:
        return 'connection_error';
      case OAuth2ExceptionType.unknown:
        return 'unknown_error';
    }
  }

  // 문자열을 Enum 값으로 변환 (역변환)
  static OAuth2ExceptionType fromString(String? value) {
    if (value == null) return OAuth2ExceptionType.unknown;

    switch (value) {
      case 'invalid_request':
        return OAuth2ExceptionType.invalidRequest;
      case 'invalid_client':
        return OAuth2ExceptionType.invalidClient;
      case 'invalid_grant':
        return OAuth2ExceptionType.invalidGrant;
      case 'unauthorized_client':
        return OAuth2ExceptionType.unauthorizedClient;
      case 'unsupported_grant_type':
        return OAuth2ExceptionType.unsupportedGrantType;
      case 'invalid_scope':
        return OAuth2ExceptionType.invalidScope;
      case 'access_denied':
        return OAuth2ExceptionType.accessDenied;
      case 'server_error':
        return OAuth2ExceptionType.serverError;
      case 'temporarily_unavailable':
        return OAuth2ExceptionType.temporarilyUnavailable;
      case 'canceled':
        return OAuth2ExceptionType.canceled; // 문자열 값에서 Enum 변환 추가
      default:
        return OAuth2ExceptionType.unknown;
    }
  }
}
