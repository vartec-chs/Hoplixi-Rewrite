import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_card_history_dto.freezed.dart';
part 'bank_card_history_dto.g.dart';

/// DTO для получения записи из истории банковской карты
@freezed
sealed class GetBankCardHistoryDto with _$GetBankCardHistoryDto {
  const factory GetBankCardHistoryDto({
    required String id,
    required String originalCardId,
    required String action,
    required String name,
    required String cardholderName,
    String? cardNumber,
    String? cardType,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    String? description,
    String? notes,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetBankCardHistoryDto;

  factory GetBankCardHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetBankCardHistoryDtoFromJson(json);
}

/// DTO для карточки истории банковской карты (основная информация)
@freezed
sealed class BankCardHistoryCardDto with _$BankCardHistoryCardDto {
  const factory BankCardHistoryCardDto({
    required String id,
    required String originalCardId,
    required String action,
    required String name,
    required String cardholderName,
    String? cardType,
    required DateTime actionAt,
  }) = _BankCardHistoryCardDto;

  factory BankCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDtoFromJson(json);
}
