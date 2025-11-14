import "package:freezed_annotation/freezed_annotation.dart";

part 'data_refresh_state.freezed.dart';

enum DataRefreshType { add, update, delete }

@freezed
sealed class DataRefreshState with _$DataRefreshState {
  const factory DataRefreshState({
    required DataRefreshType type,
    required DateTime timestamp,
    String? entityId,
  }) = _DataRefreshState;
}
