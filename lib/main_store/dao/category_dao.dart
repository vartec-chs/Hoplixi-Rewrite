import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<MainStore> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Получить все категории
  Future<List<CategoriesData>> getAllCategories() {
    return select(categories).get();
  }

  /// Получить категорию по ID
  Future<CategoriesData?> getCategoryById(String id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Получить категории в виде карточек
  Future<List<CategoryCardDto>> getAllCategoryCards() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .map(
          (c) => CategoryCardDto(
            id: c.id,
            name: c.name,
            type: c.type.value,
            color: c.color,
            iconId: c.iconId,
            itemsCount: 0, // TODO: count items in category
          ),
        )
        .get();
  }

  /// Смотреть все категории с автообновлением
  Stream<List<CategoriesData>> watchAllCategories() {
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  /// Смотреть категории карточки с автообновлением
  Stream<List<CategoryCardDto>> watchCategoryCards() {
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch().map(
      (categories) => categories
          .map(
            (c) => CategoryCardDto(
              id: c.id,
              name: c.name,
              type: c.type.value,
              color: c.color,
              iconId: c.iconId,
              itemsCount: 0, // TODO: count items in category
            ),
          )
          .toList(),
    );
  }

  /// Создать новую категорию
  Future<String> createCategory(CreateCategoryDto dto) {
    final companion = CategoriesCompanion.insert(
      name: dto.name,
      type: CategoryTypeX.fromString(dto.type),
      description: Value(dto.description),
      color: Value(dto.color ?? 'FFFFFF'),
      iconId: Value(dto.iconId),
    );
    return into(categories).insert(companion).then((id) {
      return (select(
        categories,
      )..where((c) => c.id.equals(id.toString()))).map((c) => c.id).getSingle();
    });
  }

  /// Обновить категорию
  Future<bool> updateCategory(String id, UpdateCategoryDto dto) {
    final companion = CategoriesCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      iconId: dto.iconId != null ? Value(dto.iconId) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = update(categories)..where((c) => c.id.equals(id));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Получить категории по типу
  Stream<List<CategoryCardDto>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .map(
          (categories) => categories
              .map(
                (c) => CategoryCardDto(
                  id: c.id,
                  name: c.name,
                  type: c.type.value,
                  color: c.color,
                  iconId: c.iconId,
                  itemsCount: 0, // TODO: count items in category
                ),
              )
              .toList(),
        );
  }

  /// Удалить категорию
  Future<bool> deleteCategory(String id) async {
    final rowsAffected = await (delete(
      categories,
    )..where((c) => c.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
