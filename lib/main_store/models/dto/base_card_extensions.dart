import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';

extension BaseCardDtoExtension on BaseCardDto {
  bool? get isArchived {
    if (this is PasswordCardDto) {
      return (this as PasswordCardDto).isArchived;
    }
    return null;
  }

  bool? get isDeleted {
    if (this is PasswordCardDto) {
      return (this as PasswordCardDto).isDeleted;
    }
    return null;
  }

  BaseCardDto copyWithBase({
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
  }) {
    final self = this;
    if (self is PasswordCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
        isArchived: isArchived ?? self.isArchived,
        isDeleted: isDeleted ?? self.isDeleted,
      );
    } else if (self is NoteCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
      );
    } else if (self is BankCardCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
      );
    } else if (self is FileCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
      );
    } else if (self is OtpCardDto) {
      return self.copyWith(
        isFavorite: isFavorite ?? self.isFavorite,
        isPinned: isPinned ?? self.isPinned,
      );
    }
    return self;
  }
}
