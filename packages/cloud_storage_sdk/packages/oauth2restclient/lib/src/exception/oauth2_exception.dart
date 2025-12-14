// OAuth2 오류 타입을 위한 Enum (취소 타입 추가)

// OAuth2 예외 인터페이스 (Enum 사용)
import 'oauth2_exception_type.dart';

abstract interface class OAuth2Exception {
  String? get message;
  String? get reason;
  String? get stackTrace;

  OAuth2ExceptionType get type; // Enum 타입 사용
}

// 구체적인 구현 클래스
class OAuth2ExceptionF implements OAuth2Exception {
  @override
  final String? message;

  @override
  final String? stackTrace;

  @override
  final String? reason;

  @override
  final OAuth2ExceptionType type;

  OAuth2ExceptionF({
    required this.type,
    this.message,
    this.reason,
    StackTrace? trace,
  }) : stackTrace = trace?.toString();

  // 기존 팩토리 메서드들...

  // CancelledException 팩토리 메서드 추가
  factory OAuth2ExceptionF.canceled({String? message, String? reason}) {
    return OAuth2ExceptionF(
      type: OAuth2ExceptionType.canceled,
      message: message,
      reason: reason,
      trace: StackTrace.current,
    );
  }

  factory OAuth2ExceptionF.unauthorized({String? message}) {
    return OAuth2ExceptionF(
      type: OAuth2ExceptionType.unauthorized,
      message: message,
      trace: StackTrace.current,
    );
  }
}
