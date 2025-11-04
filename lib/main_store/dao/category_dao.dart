import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:uuid/uuid.dart';

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
  Future<String> createCategory(CreateCategoryDto dto) async {
    final id = const Uuid()
        .v4(); // Генерируем уникальный ID для новой категории
    final companion = CategoriesCompanion.insert(
      id: Value(id),
      name: dto.name,
      type: CategoryTypeX.fromString(dto.type),
      description: Value(dto.description),
      color: Value(dto.color ?? 'FFFFFF'),
      iconId: Value(dto.iconId),
    );
    await into(categories).insert(companion);
    return id;
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

  /// Получить категории с пагинацией
  Future<List<CategoryCardDto>> getCategoryCardsPaginated({
    required int limit,
    required int offset,
  }) {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)])
          ..limit(limit, offset: offset))
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

  /// Удалить категорию
  Future<bool> deleteCategory(String id) async {
    final rowsAffected = await (delete(
      categories,
    )..where((c) => c.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить отфильтрованные категории
  Future<List<CategoriesData>> getCategoriesFiltered(CategoriesFilter filter) {
    var query = select(categories);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((c) => c.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((c) => c.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((c) => c.color.equals(filter.color!));
    }

    // Фильтр по наличию иконки
    if (filter.hasIcon != null) {
      if (filter.hasIcon!) {
        query = query..where((c) => c.iconId.isNotNull());
      } else {
        query = query..where((c) => c.iconId.isNull());
      }
    }

    // Фильтр по наличию описания
    if (filter.hasDescription != null) {
      if (filter.hasDescription!) {
        query = query..where((c) => c.description.isNotNull());
      } else {
        query = query..where((c) => c.description.isNull());
      }
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((c) => c.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((c) => c.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((c) => c.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((c) => c.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(c) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.get();
  }

  /// Смотреть отфильтрованные категории с автообновлением
  Stream<List<CategoriesData>> watchCategoriesFiltered(
    CategoriesFilter filter,
  ) {
    var query = select(categories);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((c) => c.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((c) => c.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((c) => c.color.equals(filter.color!));
    }

    // Фильтр по наличию иконки
    if (filter.hasIcon != null) {
      if (filter.hasIcon!) {
        query = query..where((c) => c.iconId.isNotNull());
      } else {
        query = query..where((c) => c.iconId.isNull());
      }
    }

    // Фильтр по наличию описания
    if (filter.hasDescription != null) {
      if (filter.hasDescription!) {
        query = query..where((c) => c.description.isNotNull());
      } else {
        query = query..where((c) => c.description.isNull());
      }
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((c) => c.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((c) => c.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((c) => c.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((c) => c.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(c) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.watch();
  }

  /// Получить отфильтрованные категории в виде карточек
  Future<List<CategoryCardDto>> getCategoryCardsFiltered(
    CategoriesFilter filter,
  ) async {
    final categories = await getCategoriesFiltered(filter);
    return categories
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
        .toList();
  }

  /// Смотреть отфильтрованные категории карточки с автообновлением
  Stream<List<CategoryCardDto>> watchCategoryCardsFiltered(
    CategoriesFilter filter,
  ) {
    return watchCategoriesFiltered(filter).map(
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

  /// Получить тип сортировки для Drift
  OrderingTerm _getSortOrderByTerm(CategoriesSortField sortField) {
    switch (sortField) {
      case CategoriesSortField.name:
        return OrderingTerm.asc(categories.name);
      case CategoriesSortField.type:
        return OrderingTerm.asc(categories.type);
      case CategoriesSortField.createdAt:
        return OrderingTerm.asc(categories.createdAt);
      case CategoriesSortField.modifiedAt:
        return OrderingTerm.asc(categories.modifiedAt);
    }
  }
}
