import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';

/// Провайдер для управления состоянием фильтра иконок
final iconFilterProvider = NotifierProvider<IconFilterNotifier, IconsFilter>(
  () {
    return IconFilterNotifier();
  },
);

/// Notifier для управления фильтром иконок
class IconFilterNotifier extends Notifier<IconsFilter> {
  @override
  IconsFilter build() {
    return const IconsFilter();
  }

  /// Обновить поисковый запрос
  void updateQuery(String query) {
    state = state.copyWith(query: query.trim());
  }

  /// Обновить тип иконки
  void updateType(String? type) {
    state = state.copyWith(type: type);
  }

  /// Обновить дату создания (после)
  void updateCreatedAfter(DateTime? date) {
    state = state.copyWith(createdAfter: date);
  }

  /// Обновить дату создания (до)
  void updateCreatedBefore(DateTime? date) {
    state = state.copyWith(createdBefore: date);
  }

  /// Обновить дату изменения (после)
  void updateModifiedAfter(DateTime? date) {
    state = state.copyWith(modifiedAfter: date);
  }

  /// Обновить дату изменения (до)
  void updateModifiedBefore(DateTime? date) {
    state = state.copyWith(modifiedBefore: date);
  }

  /// Обновить поле сортировки
  void updateSortField(IconsSortField sortField) {
    state = state.copyWith(sortField: sortField);
  }

  /// Обновить лимит
  void updateLimit(int? limit) {
    state = state.copyWith(limit: limit);
  }

  /// Обновить offset
  void updateOffset(int? offset) {
    state = state.copyWith(offset: offset);
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    state = const IconsFilter();
  }

  /// Обновить весь фильтр сразу
  void updateFilter(IconsFilter filter) {
    state = filter;
  }
}
