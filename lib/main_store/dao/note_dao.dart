import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/tables/notes.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<MainStore>
    with _$NoteDaoMixin
    implements BaseMainEntityDao {
  NoteDao(super.db);

  /// Получить все заметки
  Future<List<NotesData>> getAllNotes() {
    return select(notes).get();
  }

  /// Получить заметку по ID
  Future<NotesData?> getNoteById(String id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// Получить заметки в виде карточек
  Future<List<NoteCardDto>> getAllNoteCards() {
    return (select(notes)..orderBy([(n) => OrderingTerm.desc(n.modifiedAt)]))
        .map(
          (n) => NoteCardDto(
            id: n.id,
            title: n.title,
            description: n.description,
            categoryName: null, // TODO: join with categories
            isFavorite: n.isFavorite,
            isPinned: n.isPinned,
            usedCount: n.usedCount,
            modifiedAt: n.modifiedAt,
          ),
        )
        .get();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  /// Переключить архивирование
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(isArchived: Value(isArchived)),
    );

    return result > 0;
  }

  /// Смотреть все заметки с автообновлением
  Stream<List<NotesData>> watchAllNotes() {
    return (select(
      notes,
    )..orderBy([(n) => OrderingTerm.desc(n.modifiedAt)])).watch();
  }

  /// Смотреть заметки карточки с автообновлением
  Stream<List<NoteCardDto>> watchNoteCards() {
    return (select(
      notes,
    )..orderBy([(n) => OrderingTerm.desc(n.modifiedAt)])).watch().map(
      (notes) => notes
          .map(
            (n) => NoteCardDto(
              id: n.id,
              title: n.title,
              description: n.description,
              categoryName: null,
              isFavorite: n.isFavorite,
              isPinned: n.isPinned,
              usedCount: n.usedCount,
              modifiedAt: n.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Создать новую заметку
  Future<String> createNote(CreateNoteDto dto) {
    final companion = NotesCompanion.insert(
      title: dto.title,
      content: dto.content,
      deltaJson: dto.deltaJson,
      description: Value(dto.description),
      categoryId: Value(dto.categoryId),
    );
    return into(notes).insert(companion).then((id) {
      return (select(
        notes,
      )..where((n) => n.id.equals(id.toString()))).map((n) => n.id).getSingle();
    });
  }

  /// Обновить заметку
  Future<bool> updateNote(String id, UpdateNoteDto dto) async {
    final companion = NotesCompanion(
      title: dto.title != null ? Value(dto.title!) : const Value.absent(),
      content: dto.content != null ? Value(dto.content!) : const Value.absent(),
      deltaJson: dto.deltaJson != null
          ? Value(dto.deltaJson!)
          : const Value.absent(),
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
    final rowsAffected = await (update(
      attachedDatabase.notes,
    )..where((t) => t.id.equals(id))).write(companion);
    return rowsAffected > 0;
  }

  /// Мягкое удаление заметки
  @override
  Future<bool> softDelete(String id) async {
    final rowsAffected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(const NotesCompanion(isDeleted: Value(true)));
    return rowsAffected > 0;
  }

  /// Восстановить заметку из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(const NotesCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление заметки
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      notes,
    )..where((n) => n.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
