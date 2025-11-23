import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

/// DTO для создания нового файла
@freezed
sealed class CreateFileDto with _$CreateFileDto {
  const factory CreateFileDto({
    required String name,
    required String fileName,
    required String fileExtension,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    String? description,
    String? categoryId,
  }) = _CreateFileDto;

  factory CreateFileDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFileDtoFromJson(json);
}

/// DTO для получения полной информации о файле
@freezed
sealed class GetFileDto with _$GetFileDto {
  const factory GetFileDto({
    required String id,
    required String name,
    required String fileName,
    required String fileExtension,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
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
  }) = _GetFileDto;

  factory GetFileDto.fromJson(Map<String, dynamic> json) =>
      _$GetFileDtoFromJson(json);
}

/// DTO для карточки файла (основная информация для отображения)
@freezed
sealed class FileCardDto with _$FileCardDto implements BaseCardDto {
  const factory FileCardDto({
    required String id,
    required String name,
    required String fileName,
    required String fileExtension,
    required int fileSize,
    String? categoryName,
    required bool isFavorite,
    required bool isPinned,
    required int usedCount,
    required DateTime modifiedAt,
  }) = _FileCardDto;

  factory FileCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDtoFromJson(json);
}

/// DTO для обновления файла
@freezed
sealed class UpdateFileDto with _$UpdateFileDto {
  const factory UpdateFileDto({
    String? name,
    String? description,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
  }) = _UpdateFileDto;

  factory UpdateFileDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFileDtoFromJson(json);
}
