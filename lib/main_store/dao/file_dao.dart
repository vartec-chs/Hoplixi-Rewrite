import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/tables/files.dart';

part 'file_dao.g.dart';

@DriftAccessor(tables: [Files])
class FileDao extends DatabaseAccessor<MainStore>
    with _$FileDaoMixin
    implements BaseMainEntityDao {
  FileDao(super.db);

  /// Получить все файлы
  Future<List<FilesData>> getAllFiles() {
    return select(files).get();
  }

  /// Получить файл по ID
  Future<FilesData?> getFileById(String id) {
    return (select(files)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Получить файлы в виде карточек
  Future<List<FileCardDto>> getAllFileCards() {
    return (select(files)..orderBy([(f) => OrderingTerm.desc(f.modifiedAt)]))
        .map(
          (f) => FileCardDto(
            id: f.id,
            name: f.name,
            fileName: f.fileName,
            fileExtension: f.fileExtension,
            fileSize: f.fileSize,
            categoryName: null, // TODO: join with categories
            isFavorite: f.isFavorite,
            isPinned: f.isPinned,
            usedCount: f.usedCount,
            modifiedAt: f.modifiedAt,
          ),
        )
        .get();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  /// Смотреть все файлы с автообновлением
  Stream<List<FilesData>> watchAllFiles() {
    return (select(
      files,
    )..orderBy([(f) => OrderingTerm.desc(f.modifiedAt)])).watch();
  }

  /// Смотреть файлы карточки с автообновлением
  Stream<List<FileCardDto>> watchFileCards() {
    return (select(
      files,
    )..orderBy([(f) => OrderingTerm.desc(f.modifiedAt)])).watch().map(
      (files) => files
          .map(
            (f) => FileCardDto(
              id: f.id,
              name: f.name,
              fileName: f.fileName,
              fileExtension: f.fileExtension,
              fileSize: f.fileSize,
              categoryName: null,
              isFavorite: f.isFavorite,
              isPinned: f.isPinned,
              usedCount: f.usedCount,
              modifiedAt: f.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Создать новый файл
  Future<String> createFile(CreateFileDto dto) {
    final companion = FilesCompanion.insert(
      name: dto.name,
      fileName: dto.fileName,
      fileExtension: dto.fileExtension,
      filePath: dto.filePath,
      mimeType: dto.mimeType,
      fileSize: dto.fileSize,
      fileHash: dto.fileHash,
      description: Value(dto.description),
      categoryId: Value(dto.categoryId),
    );
    return into(files).insert(companion).then((id) {
      return (select(
        files,
      )..where((f) => f.id.equals(id.toString()))).map((f) => f.id).getSingle();
    });
  }

  /// Обновить файл
  Future<bool> updateFile(String id, UpdateFileDto dto) async {
    final companion = FilesCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      isArchived: dto.isArchived != null
          ? Value(dto.isArchived!)
          : const Value.absent(),
      isPinned: dto.isPinned != null
          ? Value(dto.isPinned!)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = (update(files)..where((f) => f.id.equals(id)));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Мягкое удаление файла
  @override
  Future<bool> softDelete(String id) async {
    final query = (update(files)..where((f) => f.id.equals(id)));
    return query
        .write(const FilesCompanion(isDeleted: Value(true)))
        .then((rowsAffected) => rowsAffected > 0);
  }

  /// Восстановить файл из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(files)..where((f) => f.id.equals(id)))
        .write(const FilesCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление файл
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      files,
    )..where((f) => f.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
