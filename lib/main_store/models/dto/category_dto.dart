import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

/// DTO для создания новой категории
@freezed
sealed class CreateCategoryDto with _$CreateCategoryDto {
  const factory CreateCategoryDto({
    required String name,
    required String
    type, // 'notes', 'password', 'totp', 'bankCard', 'files', 'mixed'
    String? description,
    String? color,
    String? iconId,
  }) = _CreateCategoryDto;

  factory CreateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCategoryDtoFromJson(json);
}

/// DTO для получения полной информации о категории
@freezed
sealed class GetCategoryDto with _$GetCategoryDto {
  const factory GetCategoryDto({
    required String id,
    required String name,
    required String type,
    String? description,
    String? color,
    String? iconId,
    required int itemsCount,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _GetCategoryDto;

  factory GetCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetCategoryDtoFromJson(json);
}

/// DTO для карточки категории (основная информация для отображения)
@freezed
sealed class CategoryCardDto with _$CategoryCardDto {
  const factory CategoryCardDto({
    required String id,
    required String name,
    required String type,
    String? color,
    String? iconId,
    required int itemsCount,
  }) = _CategoryCardDto;

  factory CategoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryCardDtoFromJson(json);
}

@freezed
sealed class CategoryInCardDto with _$CategoryInCardDto {
  const factory CategoryInCardDto({
    required String id,
    required String name,
    required String type,
    String? color,
    String? iconId,
  }) = _CategoryInCardDto;

  factory CategoryInCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryInCardDtoFromJson(json);
}

/// DTO для обновления категории
@freezed
sealed class UpdateCategoryDto with _$UpdateCategoryDto {
  const factory UpdateCategoryDto({
    String? name,
    String? description,
    String? color,
    String? iconId,
  }) = _UpdateCategoryDto;

  factory UpdateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCategoryDtoFromJson(json);
}
