/// Category Picker - компонент выбора категории с модальным окном
///
/// Основной виджет: CategoryPickerField
///
/// Использование (одиночный выбор):
/// ```dart
/// CategoryPickerField(
///   selectedCategoryId: categoryId,
///   selectedCategoryName: categoryName,
///   onCategorySelected: (id, name) {
///     setState(() {
///       categoryId = id;
///       categoryName = name;
///     });
///   },
/// )
/// ```
///
/// Использование (режим фильтра - множественный выбор):
/// ```dart
/// CategoryPickerField(
///   isFilter: true,
///   selectedCategoryIds: categoryIds,
///   selectedCategoryNames: categoryNames,
///   filterByType: 'login', // опционально: фильтр по типу категорий
///   onCategoriesSelected: (ids, names) {
///     setState(() {
///       categoryIds = ids;
///       categoryNames = names;
///     });
///   },
/// )
/// ```

export 'widgets/category_picker_field.dart';

// export 'widgets/category_picker_modal.dart';
// export 'widgets/category_picker_item.dart';
// export 'widgets/category_picker_filters.dart';
// export 'providers/category_picker_provider.dart';
// export 'providers/category_filter_provider.dart';
// export 'models/category_pagination_state.dart';
