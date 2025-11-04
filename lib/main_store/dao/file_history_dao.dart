import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/files_history.dart';

part 'file_history_dao.g.dart';

@DriftAccessor(tables: [FilesHistory])
class FileHistoryDao extends DatabaseAccessor<MainStore>
    with _$FileHistoryDaoMixin {
  FileHistoryDao(super.db);

  /// Получить всю историю файлов
  Future<List<FilesHistoryData>> getAllFileHistory() {
    return select(filesHistory).get();
  }

  /// Получить запись истории по ID
  Future<FilesHistoryData?> getFileHistoryById(String id) {
    return (select(
      filesHistory,
    )..where((fh) => fh.id.equals(id))).getSingleOrNull();
  }

  /// Получить историю файлов в виде карточек
  Future<List<FileHistoryCardDto>> getAllFileHistoryCards() {
    return (select(filesHistory)
          ..orderBy([(fh) => OrderingTerm.desc(fh.actionAt)]))
        .map(
          (fh) => FileHistoryCardDto(
            id: fh.id,
            originalFileId: fh.originalFileId,
            action: fh.action.value,
            name: fh.name,
            fileName: fh.fileName,
            fileExtension: fh.fileExtension,
            actionAt: fh.actionAt,
          ),
        )
        .get();
  }

  /// Смотреть всю историю файлов с автообновлением
  Stream<List<FilesHistoryData>> watchAllFileHistory() {
    return (select(
      filesHistory,
    )..orderBy([(fh) => OrderingTerm.desc(fh.actionAt)])).watch();
  }

  /// Смотреть историю файлов карточки с автообновлением
  Stream<List<FileHistoryCardDto>> watchFileHistoryCards() {
    return (select(
      filesHistory,
    )..orderBy([(fh) => OrderingTerm.desc(fh.actionAt)])).watch().map(
      (history) => history
          .map(
            (fh) => FileHistoryCardDto(
              id: fh.id,
              originalFileId: fh.originalFileId,
              action: fh.action.value,
              name: fh.name,
              fileName: fh.fileName,
              fileExtension: fh.fileExtension,
              actionAt: fh.actionAt,
            ),
          )
          .toList(),
    );
  }

  /// Получить историю для конкретного файла
  Stream<List<FileHistoryCardDto>> watchFileHistoryByOriginalId(String fileId) {
    return (select(filesHistory)
          ..where((fh) => fh.originalFileId.equals(fileId))
          ..orderBy([(fh) => OrderingTerm.desc(fh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (fh) => FileHistoryCardDto(
                  id: fh.id,
                  originalFileId: fh.originalFileId,
                  action: fh.action.value,
                  name: fh.name,
                  fileName: fh.fileName,
                  fileExtension: fh.fileExtension,
                  actionAt: fh.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Получить историю по действию
  Stream<List<FileHistoryCardDto>> watchFileHistoryByAction(String action) {
    return (select(filesHistory)
          ..where((fh) => fh.action.equals(action))
          ..orderBy([(fh) => OrderingTerm.desc(fh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (fh) => FileHistoryCardDto(
                  id: fh.id,
                  originalFileId: fh.originalFileId,
                  action: fh.action.value,
                  name: fh.name,
                  fileName: fh.fileName,
                  fileExtension: fh.fileExtension,
                  actionAt: fh.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Создать запись истории
  Future<String> createFileHistory(CreateFileHistoryDto dto) {
    final companion = FilesHistoryCompanion.insert(
      originalFileId: dto.originalFileId,
      action: ActionInHistoryX.fromString(dto.action),
      name: dto.name,
      fileName: dto.fileName,
      fileExtension: dto.fileExtension,
      filePath: dto.filePath,
      mimeType: dto.mimeType,
      fileSize: dto.fileSize,
      fileHash: dto.fileHash,
      description: Value(dto.description),
      categoryName: Value(dto.categoryName),
      usedCount: Value(dto.usedCount),
      isFavorite: Value(dto.isFavorite),
      isArchived: Value(dto.isArchived),
      isPinned: Value(dto.isPinned),
      isDeleted: Value(dto.isDeleted),
      originalCreatedAt: Value(dto.originalCreatedAt),
      originalModifiedAt: Value(dto.originalModifiedAt),
      originalLastAccessedAt: Value(dto.originalLastAccessedAt),
    );
    return into(filesHistory).insert(companion).then((id) {
      return (select(filesHistory)..where((fh) => fh.id.equals(id.toString())))
          .map((fh) => fh.id)
          .getSingle();
    });
  }

  /// Удалить историю для файла
  Future<int> deleteFileHistoryByFileId(String fileId) {
    return (delete(
      filesHistory,
    )..where((fh) => fh.originalFileId.equals(fileId))).go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldFileHistory(Duration olderThan) {
    final cutoffDate = DateTime.now().subtract(olderThan);
    return (delete(
      filesHistory,
    )..where((fh) => fh.actionAt.isSmallerThanValue(cutoffDate))).go();
  }
}
