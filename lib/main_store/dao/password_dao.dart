import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/tables/passwords.dart';

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
  Future<String> createPassword(CreatePasswordDto dto) {
    final companion = PasswordsCompanion.insert(
      name: dto.name,
      password: dto.password,
      login: Value(dto.login),
      email: Value(dto.email),
      url: Value(dto.url),
      description: Value(dto.description),
      notes: Value(dto.notes),
      categoryId: Value(dto.categoryId),
    );
    return into(passwords).insert(companion).then((id) {
      // id уже UUID, возвращаем его строкой
      return (select(
        passwords,
      )..where((p) => p.id.equals(id.toString()))).map((p) => p.id).getSingle();
    });
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

  /// Удалить пароль (мягкое удаление)
  Future<bool> softDeletePassword(String id) async {
    final result = await (update(passwords)
          ..where((p) => p.id.equals(id))).write(
      const PasswordsCompanion(isDeleted: Value(true)),
    );
    return result > 0;
  }

  /// Получить пароли по категории
  Stream<List<PasswordCardDto>> watchPasswordsByCategory(String? categoryId) {
    var query = select(passwords);
    if (categoryId != null) {
      query = query..where((p) => p.categoryId.equals(categoryId));
    } else {
      query = query..where((p) => p.categoryId.isNull());
    }
    return (query..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)]))
        .watch()
        .map(
          (passwords) => passwords
              .map(
                (p) => PasswordCardDto(
                  id: p.id,
                  name: p.name,
                  login: p.login,
                  email: p.email,
                  url: p.url,
                  categoryName: null,
                  isFavorite: p.isFavorite,
                  isPinned: p.isPinned,
                  usedCount: p.usedCount,
                  modifiedAt: p.modifiedAt,
                ),
              )
              .toList(),
        );
  }

  /// Получить избранные пароли
  Stream<List<PasswordCardDto>> watchFavoritePasswords() {
    return (select(passwords)
          ..where((p) => p.isFavorite.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.modifiedAt)]))
        .watch()
        .map(
          (passwords) => passwords
              .map(
                (p) => PasswordCardDto(
                  id: p.id,
                  name: p.name,
                  login: p.login,
                  email: p.email,
                  url: p.url,
                  categoryName: null,
                  isFavorite: p.isFavorite,
                  isPinned: p.isPinned,
                  usedCount: p.usedCount,
                  modifiedAt: p.modifiedAt,
                ),
              )
              .toList(),
        );
  }
}
