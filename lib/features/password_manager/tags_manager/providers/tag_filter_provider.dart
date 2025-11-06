import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';

/// Провайдер для управления состоянием фильтра тегов
final tagFilterProvider = NotifierProvider<TagFilterNotifier, TagsFilter>(
  () => TagFilterNotifier(),
);

/// Notifier для управления фильтром тегов
class TagFilterNotifier extends Notifier<TagsFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  TagsFilter build() {
    // Очищаем таймер при destroy провайдера
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return TagsFilter.create(sortField: TagsSortField.name, limit: 30);
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: query.trim());
    });
  }

  /// Обновить тип тега
  Future<void> updateType(String? type) async {
    state = state.copyWith(type: type);
    await Future.microtask(() {});
  }

  /// Обновить цвет
  Future<void> updateColor(String? color) async {
    state = state.copyWith(color: color);
    await Future.microtask(() {});
  }

  /// Обновить дату создания (после)
  Future<void> updateCreatedAfter(DateTime? date) async {
    state = state.copyWith(createdAfter: date);
    await Future.microtask(() {});
  }

  /// Обновить дату создания (до)
  Future<void> updateCreatedBefore(DateTime? date) async {
    state = state.copyWith(createdBefore: date);
    await Future.microtask(() {});
  }

  /// Обновить дату изменения (после)
  Future<void> updateModifiedAfter(DateTime? date) async {
    state = state.copyWith(modifiedAfter: date);
    await Future.microtask(() {});
  }

  /// Обновить дату изменения (до)
  Future<void> updateModifiedBefore(DateTime? date) async {
    state = state.copyWith(modifiedBefore: date);
    await Future.microtask(() {});
  }

  /// Обновить поле сортировки
  Future<void> updateSortField(TagsSortField sortField) async {
    state = state.copyWith(sortField: sortField);
    await Future.microtask(() {});
  }

  /// Обновить лимит
  Future<void> updateLimit(int? limit) async {
    state = state.copyWith(limit: limit);
    await Future.microtask(() {});
  }

  /// Обновить offset
  Future<void> updateOffset(int? offset) async {
    state = state.copyWith(offset: offset);
    await Future.microtask(() {});
  }

  /// Сбросить фильтр к начальному состоянию
  Future<void> reset() async {
    _debounceTimer?.cancel();
    state = TagsFilter.create(sortField: TagsSortField.name, limit: 30);
    await Future.microtask(() {});
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(TagsFilter filter) async {
    _debounceTimer?.cancel();
    state = filter;
    await Future.microtask(() {});
  }
}
