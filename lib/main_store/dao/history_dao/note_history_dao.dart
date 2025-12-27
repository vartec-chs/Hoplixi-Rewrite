import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/note_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/notes_history.dart';

part '../note_history_dao.g.dart';

@DriftAccessor(tables: [NotesHistory])
class NoteHistoryDao extends DatabaseAccessor<MainStore>
    with _$NoteHistoryDaoMixin {
  NoteHistoryDao(super.db);

  /// Получить всю историю заметок
  Future<List<NotesHistoryData>> getAllNoteHistory() {
    return select(notesHistory).get();
  }

  /// Получить запись истории по ID
  Future<NotesHistoryData?> getNoteHistoryById(String id) {
    return (select(
      notesHistory,
    )..where((nh) => nh.id.equals(id))).getSingleOrNull();
  }

  /// Получить историю заметок в виде карточек
  Future<List<NoteHistoryCardDto>> getAllNoteHistoryCards() {
    return (select(notesHistory)
          ..orderBy([(nh) => OrderingTerm.desc(nh.actionAt)]))
        .map(
          (nh) => NoteHistoryCardDto(
            id: nh.id,
            originalNoteId: nh.originalNoteId,
            action: nh.action.value,
            title: nh.title,
            actionAt: nh.actionAt,
          ),
        )
        .get();
  }

  /// Смотреть всю историю заметок с автообновлением
  Stream<List<NotesHistoryData>> watchAllNoteHistory() {
    return (select(
      notesHistory,
    )..orderBy([(nh) => OrderingTerm.desc(nh.actionAt)])).watch();
  }

  /// Смотреть историю заметок карточки с автообновлением
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryCards() {
    return (select(
      notesHistory,
    )..orderBy([(nh) => OrderingTerm.desc(nh.actionAt)])).watch().map(
      (history) => history
          .map(
            (nh) => NoteHistoryCardDto(
              id: nh.id,
              originalNoteId: nh.originalNoteId,
              action: nh.action.value,
              title: nh.title,
              actionAt: nh.actionAt,
            ),
          )
          .toList(),
    );
  }

  /// Получить историю для конкретной заметки
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryByOriginalId(String noteId) {
    return (select(notesHistory)
          ..where((nh) => nh.originalNoteId.equals(noteId))
          ..orderBy([(nh) => OrderingTerm.desc(nh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (nh) => NoteHistoryCardDto(
                  id: nh.id,
                  originalNoteId: nh.originalNoteId,
                  action: nh.action.value,
                  title: nh.title,
                  actionAt: nh.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Получить историю по действию
  Stream<List<NoteHistoryCardDto>> watchNoteHistoryByAction(String action) {
    return (select(notesHistory)
          ..where((nh) => nh.action.equals(action))
          ..orderBy([(nh) => OrderingTerm.desc(nh.actionAt)]))
        .watch()
        .map(
          (history) => history
              .map(
                (nh) => NoteHistoryCardDto(
                  id: nh.id,
                  originalNoteId: nh.originalNoteId,
                  action: nh.action.value,
                  title: nh.title,
                  description: nh.description,
                  actionAt: nh.actionAt,
                ),
              )
              .toList(),
        );
  }

  /// Создать запись истории
  Future<String> createNoteHistory(CreateNoteHistoryDto dto) {
    final companion = NotesHistoryCompanion.insert(
      originalNoteId: dto.originalNoteId,
      action: ActionInHistoryX.fromString(dto.action),
      title: dto.title,
      content: dto.content,
      deltaJson: dto.deltaJson,
      description: Value(dto.description),
      categoryName: Value(dto.categoryName),
      usedCount: Value(dto.usedCount ?? 0),
      isFavorite: Value(dto.isFavorite ?? false),
      isArchived: Value(dto.isArchived ?? false),
      isPinned: Value(dto.isPinned ?? false),
      isDeleted: Value(dto.isDeleted ?? false),
      originalCreatedAt: Value(dto.originalCreatedAt),
      originalModifiedAt: Value(dto.originalModifiedAt),
    );
    return into(notesHistory).insert(companion).then((id) {
      return (select(notesHistory)..where((nh) => nh.id.equals(id.toString())))
          .map((nh) => nh.id)
          .getSingle();
    });
  }

  /// Удалить историю для заметки
  Future<int> deleteNoteHistoryByNoteId(String noteId) {
    return (delete(
      notesHistory,
    )..where((nh) => nh.originalNoteId.equals(noteId))).go();
  }

  /// Удалить старую историю (старше N дней)
  Future<int> deleteOldNoteHistory(Duration olderThan) {
    final cutoffDate = DateTime.now().subtract(olderThan);
    return (delete(
      notesHistory,
    )..where((nh) => nh.actionAt.isSmallerThanValue(cutoffDate))).go();
  }
}
