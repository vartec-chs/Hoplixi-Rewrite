import 'dart:async';

abstract interface class OAuth2CancelToken {
  /// 토큰이 취소되었는지 여부
  bool get isCancelled;

  String? get reason;

  /// 토큰이 취소되면 완료되는 Future
  Future<void> get cancelFuture;

  /// 토큰이 이미 취소되었다면 예외를 발생시킵니다
  void throwIfCancelled();

  void cancel(String? reason);
}

class OAuth2CancelTokenF implements OAuth2CancelToken {
  bool _isCancelled = false;
  final Completer<void> _cancelCompleter = Completer<void>();

  @override
  bool get isCancelled => _isCancelled;

  @override
  Future<void> get cancelFuture => _cancelCompleter.future;

  @override
  void throwIfCancelled() {
    if (_isCancelled) {
      throw Exception("Operation was cancelled");
    }
  }

  @override
  void cancel(String? reason) {
    if (!_isCancelled) {
      _reason = reason;
      _isCancelled = true;
      _cancelCompleter.complete();
    }
  }

  String? _reason;
  @override
  String? get reason => _reason;
}
