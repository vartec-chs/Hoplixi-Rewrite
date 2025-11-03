import 'package:drift/drift.dart';
import 'bank_cards.dart';
import 'tags.dart';

@DataClassName('BankCardsTagsData')
class BankCardsTags extends Table {
  TextColumn get cardId =>
      text().references(BankCards, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {cardId, tagId};

  @override
  String get tableName => 'bank_cards_tags';
}
