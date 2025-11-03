import 'package:drift/drift.dart';
import 'files.dart';
import 'tags.dart';

@DataClassName('FilesTagsData')
class FilesTags extends Table {
  TextColumn get fileId =>
      text().references(Files, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {fileId, tagId};

  @override
  String get tableName => 'files_tags';
}
