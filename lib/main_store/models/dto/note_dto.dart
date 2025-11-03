import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_dto.freezed.dart';
part 'note_dto.g.dart';

/// DTO для создания новой заметки
@freezed
sealed class CreateNoteDto with _$CreateNoteDto {
  const factory CreateNoteDto({
    required String title,
    required String content,
    required String deltaJson,
    String? description,
    String? categoryId,
  }) = _CreateNoteDto;

  factory CreateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteDtoFromJson(json);
}

/// DTO для получения полной информации о заметке
@freezed
sealed class GetNoteDto with _$GetNoteDto {
  const factory GetNoteDto({
    required String id,
    required String title,
    required String content,
    required String deltaJson,
    String? description,
    String? categoryId,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessedAt,
    required List<String> tags,
  }) = _GetNoteDto;

  factory GetNoteDto.fromJson(Map<String, dynamic> json) =>
      _$GetNoteDtoFromJson(json);
}

/// DTO для карточки заметки (основная информация для отображения)
@freezed
sealed class NoteCardDto with _$NoteCardDto {
  const factory NoteCardDto({
    required String id,
    required String title,
    String? description,
    String? categoryName,
    required bool isFavorite,
    required bool isPinned,
    required int usedCount,
    required DateTime modifiedAt,
  }) = _NoteCardDto;

  factory NoteCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoteCardDtoFromJson(json);
}

/// DTO для обновления заметки
@freezed
sealed class UpdateNoteDto with _$UpdateNoteDto {
  const factory UpdateNoteDto({
    String? title,
    String? content,
    String? deltaJson,
    String? description,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
  }) = _UpdateNoteDto;

  factory UpdateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteDtoFromJson(json);
}
