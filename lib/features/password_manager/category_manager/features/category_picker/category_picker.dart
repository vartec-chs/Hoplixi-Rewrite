/// Category Picker - компонент выбора категории с модальным окном
///
/// Основной виджет: CategoryPickerField
/// Использование:
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

export 'widgets/category_picker_field.dart';

// export 'widgets/category_picker_modal.dart';
// export 'widgets/category_picker_item.dart';
// export 'widgets/category_picker_filters.dart';
// export 'providers/category_picker_provider.dart';
// export 'providers/category_filter_provider.dart';
// export 'models/category_pagination_state.dart';
