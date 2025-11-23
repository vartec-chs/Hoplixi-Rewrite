import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';

part 'bank_card_dto.freezed.dart';
part 'bank_card_dto.g.dart';

/// DTO для создания новой банковской карты
@freezed
sealed class CreateBankCardDto with _$CreateBankCardDto {
  const factory CreateBankCardDto({
    required String name,
    required String cardholderName,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    String? cardType,
    String? cardNetwork,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    String? description,
    String? notes,
    String? categoryId,
  }) = _CreateBankCardDto;

  factory CreateBankCardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateBankCardDtoFromJson(json);
}

/// DTO для получения полной информации о банковской карте
@freezed
sealed class GetBankCardDto with _$GetBankCardDto {
  const factory GetBankCardDto({
    required String id,
    required String name,
    required String cardholderName,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    String? cardType,
    String? cardNetwork,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
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
  }) = _GetBankCardDto;

  factory GetBankCardDto.fromJson(Map<String, dynamic> json) =>
      _$GetBankCardDtoFromJson(json);
}

/// DTO для карточки банковской карты (основная информация для отображения)
@freezed
sealed class BankCardCardDto with _$BankCardCardDto implements BaseCardDto {
  const factory BankCardCardDto({
    required String id,
    required String name,
    required String cardholderName,
    String? cardType,
    String? cardNetwork,
    String? bankName,
    String? categoryName,
    required bool isFavorite,
    required bool isPinned,
    required int usedCount,
    required DateTime modifiedAt,
  }) = _BankCardCardDto;

  factory BankCardCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardCardDtoFromJson(json);
}

/// DTO для обновления банковской карты
@freezed
sealed class UpdateBankCardDto with _$UpdateBankCardDto {
  const factory UpdateBankCardDto({
    String? name,
    String? cardholderName,
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? cardType,
    String? cardNetwork,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    String? description,
    String? notes,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
  }) = _UpdateBankCardDto;

  factory UpdateBankCardDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateBankCardDtoFromJson(json);
}
