import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_errors.freezed.dart';

/// Ошибки сервиса хранения настроек
@freezed
class StorageError with _$StorageError implements Exception {
  const StorageError._();

  /// Биометрическая аутентификация не пройдена
  const factory StorageError.biometricAuthFailed({
    @Default('Биометрическая аутентификация не пройдена') String message,
  }) = _BiometricAuthFailed;

  /// Биометрическая аутентификация отменена пользователем
  const factory StorageError.biometricAuthCanceled() = _BiometricAuthCanceled;

  /// Биометрия недоступна
  const factory StorageError.biometricNotAvailable() = _BiometricNotAvailable;

  /// Неподдерживаемый тип данных
  const factory StorageError.unsupportedType(String typeName) =
      _UnsupportedType;
}
