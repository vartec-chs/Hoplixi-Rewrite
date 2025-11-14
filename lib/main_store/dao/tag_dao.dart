import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:uuid/uuid.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<MainStore> with _$TagDaoMixin {
  TagDao(super.db);

  /// Получить все теги
  Future<List<TagsData>> getAllTags() {
    return select(tags).get();
  }

  /// Получить тег по ID
  Future<TagsData?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Получить теги в виде карточек
  Future<List<TagCardDto>> getAllTagCards() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .map(
          (t) => TagCardDto(
            id: t.id,
            name: t.name,
            type: t.type.value,
            color: t.color,
            itemsCount: 0, // TODO: count items with tag
          ),
        )
        .get();
  }

  /// Смотреть все теги с автообновлением
  Stream<List<TagsData>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Смотреть теги карточки с автообновлением
  Stream<List<TagCardDto>> watchTagCards() {
    return (select(
      tags,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch().map(
      (tags) => tags
          .map(
            (t) => TagCardDto(
              id: t.id,
              name: t.name,
              type: t.type.value,
              color: t.color,
              itemsCount: 0, // TODO: count items with tag
            ),
          )
          .toList(),
    );
  }

  /// Создать новый тег
  Future<String> createTag(CreateTagDto dto) async {
    final id = const Uuid().v4(); // Генерируем уникальный ID для нового тега
    final companion = TagsCompanion.insert(
      id: Value(id),
      name: dto.name,
      type: TagTypeX.fromString(dto.type),
      color: Value(dto.color ?? 'FFFFFF'),
    );
    await into(tags).insert(companion);
    return id;
  }

  /// Обновить тег
  Future<bool> updateTag(String id, UpdateTagDto dto) {
    final companion = TagsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = update(tags)..where((t) => t.id.equals(id));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Получить теги по типу
  Stream<List<TagCardDto>> watchTagsByType(String type) {
    return (select(tags)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map(
          (tags) => tags
              .map(
                (t) => TagCardDto(
                  id: t.id,
                  name: t.name,
                  type: t.type.value,
                  color: t.color,
                  itemsCount: 0, // TODO: count items with tag
                ),
              )
              .toList(),
        );
  }

  /// Получить теги с пагинацией
  Future<List<TagCardDto>> getTagCardsPaginated({
    required int limit,
    required int offset,
  }) {
    return (select(tags)
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit, offset: offset))
        .map(
          (t) => TagCardDto(
            id: t.id,
            name: t.name,
            type: t.type.value,
            color: t.color,
            itemsCount: 0, // TODO: count items with tag
          ),
        )
        .get();
  }

  /// Удалить тег
  Future<bool> deleteTag(String id) async {
    final rowsAffected = await (delete(
      tags,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить отфильтрованные теги
  Future<List<TagsData>> getTagsFiltered(TagsFilter filter) {
    var query = select(tags);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((t) => t.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((t) => t.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((t) => t.color.equals(filter.color!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((t) => t.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((t) => t.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((t) => t.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((t) => t.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(t) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.get();
  }

  /// Получить теги по списку ID
  Future<List<TagsData>> getTagsByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(tags)..where((t) => t.id.isIn(ids))).get();
  }

  /// Смотреть отфильтрованные теги с автообновлением
  Stream<List<TagsData>> watchTagsFiltered(TagsFilter filter) {
    var query = select(tags);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((t) => t.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where((t) => t.type.equals(filter.type!));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((t) => t.color.equals(filter.color!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((t) => t.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((t) => t.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((t) => t.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((t) => t.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(t) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.watch();
  }

  /// Получить отфильтрованные теги в виде карточек
  Future<List<TagCardDto>> getTagCardsFiltered(TagsFilter filter) async {
    final tags = await getTagsFiltered(filter);
    return tags
        .map(
          (t) => TagCardDto(
            id: t.id,
            name: t.name,
            type: t.type.value,
            color: t.color,
            itemsCount: 0, // TODO: count items with tag
          ),
        )
        .toList();
  }

  /// Смотреть отфильтрованные теги карточки с автообновлением
  Stream<List<TagCardDto>> watchTagCardsFiltered(TagsFilter filter) {
    return watchTagsFiltered(filter).map(
      (tags) => tags
          .map(
            (t) => TagCardDto(
              id: t.id,
              name: t.name,
              type: t.type.value,
              color: t.color,
              itemsCount: 0, // TODO: count items with tag
            ),
          )
          .toList(),
    );
  }

  /// Получить тип сортировки для Drift
  OrderingTerm _getSortOrderByTerm(TagsSortField sortField) {
    switch (sortField) {
      case TagsSortField.name:
        return OrderingTerm.asc(tags.name);
      case TagsSortField.type:
        return OrderingTerm.asc(tags.type);
      case TagsSortField.createdAt:
        return OrderingTerm.asc(tags.createdAt);
      case TagsSortField.modifiedAt:
        return OrderingTerm.asc(tags.modifiedAt);
    }
  }
}
