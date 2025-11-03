import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_dto.freezed.dart';
part 'password_dto.g.dart';

/// DTO для создания нового пароля
@freezed
sealed class CreatePasswordDto with _$CreatePasswordDto {
  const factory CreatePasswordDto({
    required String name,
    required String password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? notes,
    String? categoryId,
  }) = _CreatePasswordDto;

  factory CreatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePasswordDtoFromJson(json);
}

/// DTO для получения полной информации о пароле
@freezed
sealed class GetPasswordDto with _$GetPasswordDto {
  const factory GetPasswordDto({
    required String id,
    required String name,
    required String password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? notes,
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
  }) = _GetPasswordDto;

  factory GetPasswordDto.fromJson(Map<String, dynamic> json) =>
      _$GetPasswordDtoFromJson(json);
}

/// DTO для карточки пароля (основная информация для отображения)
@freezed
sealed class PasswordCardDto with _$PasswordCardDto {
  const factory PasswordCardDto({
    required String id,
    required String name,
    String? login,
    String? email,
    String? url,
    String? categoryName,
    required bool isFavorite,
    required bool isPinned,
    required int usedCount,
    required DateTime modifiedAt,
  }) = _PasswordCardDto;

  factory PasswordCardDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordCardDtoFromJson(json);
}

/// DTO для обновления пароля
@freezed
sealed class UpdatePasswordDto with _$UpdatePasswordDto {
  const factory UpdatePasswordDto({
    String? name,
    String? password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? notes,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
  }) = _UpdatePasswordDto;

  factory UpdatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePasswordDtoFromJson(json);
}
