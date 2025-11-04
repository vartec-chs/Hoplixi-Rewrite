import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';

/// Notifier для управления фильтрацией категорий
class CategoryFilterNotifier extends Notifier<CategoriesFilter> {
  @override
  CategoriesFilter build() {
    return CategoriesFilter.create(
      sortField: CategoriesSortField.name,
      limit: 20,
    );
  }

  /// Обновить поисковый запрос
  void updateSearchQuery(String query) {
    state = CategoriesFilter.create(
      query: query,
      sortField: state.sortField,
      limit: state.limit,
    );
  }

  /// Обновить поле сортировки
  void updateSortField(CategoriesSortField sortField) {
    state = CategoriesFilter.create(
      query: state.query,
      sortField: sortField,
      limit: state.limit,
    );
  }

  /// Очистить фильтры
  void reset() {
    state = CategoriesFilter.create(
      sortField: CategoriesSortField.name,
      limit: 20,
    );
  }
}

/// Провайдер для фильтра категорий
final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoriesFilter>(
      CategoryFilterNotifier.new,
    );
