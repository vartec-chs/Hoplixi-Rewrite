import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_form_state.freezed.dart';

/// Состояние формы заметки
@freezed
sealed class NoteFormState with _$NoteFormState {
  const factory NoteFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingNoteId,

    // Основные поля формы
    @Default('') String title,
    @Default('') String content,
    @Default('[]') String deltaJson,
    @Default('') String description,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,

    // Ошибки валидации
    String? titleError,
    String? contentError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,

    // Флаг изменений
    @Default(false) bool hasUnsavedChanges,
  }) = _NoteFormState;

  const NoteFormState._();

  /// Проверка валидности формы
  bool get isValid {
    return titleError == null &&
        contentError == null &&
        title.isNotEmpty &&
        content.isNotEmpty;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return titleError != null || contentError != null;
  }
}
