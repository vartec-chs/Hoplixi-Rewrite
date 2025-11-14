import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/tables/password_tags.dart';
import 'package:hoplixi/main_store/tables/passwords.dart';
import 'package:uuid/uuid.dart';

part 'password_dao.g.dart';

@DriftAccessor(tables: [Passwords])
class PasswordDao extends DatabaseAccessor<MainStore> with _$PasswordDaoMixin {
  PasswordDao(super.db);

  /// Получить все пароли
  Future<List<PasswordsData>> getAllPasswords() async {
    final query = select(passwords);
    final results = await query.get();
    return results;
  }

  /// Получить пароль по ID
  Future<PasswordsData?> getPasswordById(String id) {
    return (select(passwords)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Получить пароли в виде карточек (для списка)
  Future<List<PasswordCardDto>> getAllPasswordCards() {
    return (select(passwords)
          ..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)]))
        .map(
          (p) => PasswordCardDto(
            id: p.id,
            name: p.name,
            login: p.login,
            email: p.email,
            url: p.url,
            categoryName: null, // TODO: join with categories
            isFavorite: p.isFavorite,
            isPinned: p.isPinned,
            usedCount: p.usedCount,
            modifiedAt: p.modifiedAt,
          ),
        )
        .get();
  }

  // toggle favorite
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(PasswordsCompanion(isFavorite: Value(isFavorite)));

    return result > 0;
  }

  /// Смотреть все пароли с автообновлением
  Stream<List<PasswordsData>> watchAllPasswords() {
    return (select(
      passwords,
    )..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)])).watch();
  }

  /// Смотреть карточки паролей с автообновлением
  Stream<List<PasswordCardDto>> watchPasswordCards() {
    return (select(
      passwords,
    )..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)])).watch().map(
      (passwords) => passwords
          .map(
            (p) => PasswordCardDto(
              id: p.id,
              name: p.name,
              login: p.login,
              email: p.email,
              url: p.url,
              categoryName: null, // TODO: join with categories
              isFavorite: p.isFavorite,
              isPinned: p.isPinned,
              usedCount: p.usedCount,
              modifiedAt: p.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Создать новый пароль
  Future<String> createPassword(CreatePasswordDto dto) async {
    final uuid = const Uuid().v4();
    return await db.transaction(() async {
      // 1. Создаем запись пароля
      final companion = PasswordsCompanion.insert(
        id: Value(uuid),
        name: dto.name,
        password: dto.password,
        login: Value(dto.login),
        email: Value(dto.email),
        url: Value(dto.url),
        description: Value(dto.description),
        notes: Value(dto.notes),
        categoryId: Value(dto.categoryId),
      );

      await into(passwords).insert(companion);
      await _insertPasswordTags(uuid, dto.tagsIds);

      return uuid;
    });
  }

  Future<void> _insertPasswordTags(
    String passwordId,
    List<String>? tagIds,
  ) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await db
          .into(db.passwordsTags)
          .insert(
            PasswordsTagsCompanion.insert(passwordId: passwordId, tagId: tagId),
          );
    }
  }

  /// Обновить пароль
  Future<bool> updatePassword(String id, UpdatePasswordDto dto) async {
    final companion = PasswordsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      password: dto.password != null
          ? Value(dto.password!)
          : const Value.absent(),
      login: dto.login != null ? Value(dto.login) : const Value.absent(),
      email: dto.email != null ? Value(dto.email) : const Value.absent(),
      url: dto.url != null ? Value(dto.url) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      notes: dto.notes != null ? Value(dto.notes) : const Value.absent(),
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

    final result = await (update(
      passwords,
    )..where((p) => p.id.equals(id))).write(companion);

    return result > 0;
  }

  Future<List<String>> getPasswordTagIds(String passwordId) async {
    final rows = await (select(
      db.passwordsTags,
    )..where((t) => t.passwordId.equals(passwordId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  Future<void> syncPasswordTags(String passwordId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        db.passwordsTags,
      )..where((t) => t.passwordId.equals(passwordId))).get();
      final existingIds = existing.map((row) => row.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(db.passwordsTags)..where(
              (t) => t.passwordId.equals(passwordId) & t.tagId.isIn(toDelete),
            ))
            .go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await db
            .into(db.passwordsTags)
            .insert(
              PasswordsTagsCompanion.insert(
                passwordId: passwordId,
                tagId: tagId,
              ),
            );
      }
    });
  }

  /// Удалить пароль (мягкое удаление)
  Future<bool> softDelete(String id) async {
    final result = await (update(passwords)..where((p) => p.id.equals(id)))
        .write(const PasswordsCompanion(isDeleted: Value(true)));
    return result > 0;
  }
}
