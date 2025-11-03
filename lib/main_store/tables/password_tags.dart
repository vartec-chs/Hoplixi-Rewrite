import 'package:drift/drift.dart';
import 'passwords.dart';
import 'tags.dart';

@DataClassName('PasswordsTagsData')
class PasswordsTags extends Table {
  TextColumn get passwordId =>
      text().references(Passwords, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {passwordId, tagId};

  @override
  String get tableName => 'password_tags';
}
