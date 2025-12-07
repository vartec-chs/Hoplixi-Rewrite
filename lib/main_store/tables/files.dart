import 'package:drift/drift.dart';
import 'categories.dart';
import 'package:uuid/uuid.dart';

@DataClassName('FilesData')
class Files extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text()(); // Original file name
  TextColumn get fileExtension => text()(); // File extension (e.g., .pdf, .txt)
  TextColumn get filePath =>
      text().nullable()(); // Relative path from files directory
  TextColumn get mimeType => text()(); // MIME type (e.g., application/pdf)
  IntColumn get fileSize => integer()(); // File size in bytes
  TextColumn get fileHash =>
      text().nullable()(); // SHA256 hash for integrity check
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to categories

  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'files';
}
