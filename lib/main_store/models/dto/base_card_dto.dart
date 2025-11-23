abstract interface class BaseCardDto {
  String get id;
  bool get isFavorite;
  bool get isPinned;
  int get usedCount;
  DateTime get modifiedAt;
}
