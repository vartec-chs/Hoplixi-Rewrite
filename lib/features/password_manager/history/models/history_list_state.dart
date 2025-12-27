import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/history/models/history_item.dart';

part 'history_list_state.freezed.dart';

/// Состояние списка истории с поддержкой пагинации
@freezed
sealed class HistoryListState with _$HistoryListState {
  const HistoryListState._();

  const factory HistoryListState({
    /// Список элементов истории
    @Default([]) List<HistoryItem> items,

    /// Флаг загрузки (первичной)
    @Default(false) bool isLoading,

    /// Флаг загрузки следующей страницы
    @Default(false) bool isLoadingMore,

    /// Есть ли ещё данные для подгрузки
    @Default(true) bool hasMore,

    /// Текущая страница
    @Default(1) int currentPage,

    /// Общее количество записей
    @Default(0) int totalCount,

    /// Ошибка, если есть
    String? error,
  }) = _HistoryListState;

  /// Проверяет наличие ошибки
  bool get hasError => error != null;

  /// Проверяет, пуст ли список
  bool get isEmpty => items.isEmpty && !isLoading;
}
