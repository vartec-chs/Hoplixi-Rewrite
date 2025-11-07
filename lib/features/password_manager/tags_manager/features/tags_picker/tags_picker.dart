/// Tags Picker - компонент выбора тегов с модальным окном и множественным выбором
///
/// Основной виджет: TagPickerField
/// Использование:
/// ```dart
/// TagPickerField(
///   selectedTagIds: tagIds,
///   selectedTagNames: tagNames,
///   maxTagPicks: 5, // опционально, ограничение на количество тегов
///   onTagsSelected: (ids, names) {
///     setState(() {
///       tagIds = ids;
///       tagNames = names;
///     });
///   },
/// )
/// ```

export 'widgets/tag_picker_field.dart';

// export 'widgets/tag_picker_modal.dart';
// export 'widgets/tag_picker_item.dart';
// export 'widgets/tag_picker_filters.dart';
// export 'providers/tag_picker_provider.dart';
// export 'providers/tag_filter_provider.dart';
// export 'models/tag_pagination_state.dart';
