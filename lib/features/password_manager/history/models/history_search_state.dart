import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_search_state.freezed.dart';

/// Состояние поиска в истории
///
/// Выделено в отдельный провайдер для будущего расширения фильтрами
@freezed
sealed class HistorySearchState with _$HistorySearchState {
  const HistorySearchState._();

  const factory HistorySearchState({
    /// Текущий поисковый запрос
    @Default('') String query,

    /// Флаг активности поиска
    @Default(false) bool isSearching,

    // TODO: Добавить фильтры в будущем
    // String? actionFilter,
    // DateTime? dateFrom,
    // DateTime? dateTo,
  }) = _HistorySearchState;

  /// Проверяет, есть ли активный поиск
  bool get hasActiveSearch => query.isNotEmpty;

  /// Сбрасывает состояние поиска
  HistorySearchState cleared() => const HistorySearchState();
}
