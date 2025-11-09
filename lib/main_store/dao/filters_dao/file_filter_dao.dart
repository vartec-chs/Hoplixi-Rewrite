import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/files_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'file_filter_dao.g.dart';

@DriftAccessor(tables: [Files, Categories, FilesTags])
class FileFilterDao extends DatabaseAccessor<MainStore>
    with _$FileFilterDaoMixin {
  FileFilterDao(super.db);

  /// Получить отфильтрованные файлы
  Future<List<FileCardDto>> getFilteredFiles(FilesFilter filter) async {
    final query = select(files).join([
      leftOuterJoin(categories, categories.id.equalsExp(files.categoryId)),
    ]);

    final whereExpression = _buildWhereExpression(filter);
    if (whereExpression != null) {
      query.where(whereExpression);
    }

    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final results = await query.get();

    return results.map((row) {
      final file = row.readTable(files);
      final category = row.readTableOrNull(categories);

      return FileCardDto(
        id: file.id,
        name: file.name,
        fileName: file.fileName,
        fileExtension: file.fileExtension,
        fileSize: file.fileSize,
        categoryName: category?.name,
        isFavorite: file.isFavorite,
        isPinned: file.isPinned,
        usedCount: file.usedCount,
        modifiedAt: file.modifiedAt,
      );
    }).toList();
  }

  /// Построить WHERE выражение на основе фильтра
  Expression<bool>? _buildWhereExpression(FilesFilter filter) {
    final expressions = <Expression<bool>>[];

    // Применяем базовые фильтры
    _applyBaseFilters(filter.base, expressions);

    // Применяем специфичные для файлов фильтры
    _applyFileSpecificFilters(filter, expressions);

    if (expressions.isEmpty) return null;

    return expressions.reduce((a, b) => a & b);
  }

  /// Применить базовые фильтры из BaseFilter
  void _applyBaseFilters(BaseFilter base, List<Expression<bool>> expressions) {
    // Фильтр по поисковому запросу
    if (base.query.isNotEmpty) {
      final queryLower = base.query.toLowerCase();
      expressions.add(
        files.name.lower().like('%$queryLower%') |
            files.fileName.lower().like('%$queryLower%') |
            files.description.lower().like('%$queryLower%'),
      );
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expressions.add(files.categoryId.isIn(base.categoryIds));
    }

    // Фильтр по тегам (EXISTS subquery)
    if (base.tagIds.isNotEmpty) {
      final tagFilter = existsQuery(
        select(filesTags)..where(
          (t) => t.fileId.equalsExp(files.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expressions.add(tagFilter);
    }

    // Фильтр по дате создания
    if (base.createdAfter != null) {
      expressions.add(files.createdAt.isBiggerOrEqualValue(base.createdAfter!));
    }
    if (base.createdBefore != null) {
      expressions.add(
        files.createdAt.isSmallerOrEqualValue(base.createdBefore!),
      );
    }

    // Фильтр по дате модификации
    if (base.modifiedAfter != null) {
      expressions.add(
        files.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!),
      );
    }
    if (base.modifiedBefore != null) {
      expressions.add(
        files.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!),
      );
    }

    // Фильтр по дате последнего доступа
    if (base.lastAccessedAfter != null) {
      expressions.add(
        files.lastAccessedAt.isBiggerOrEqualValue(base.lastAccessedAfter!) |
            files.lastAccessedAt.isNull(),
      );
    }
    if (base.lastAccessedBefore != null) {
      expressions.add(
        files.lastAccessedAt.isSmallerOrEqualValue(base.lastAccessedBefore!) |
            files.lastAccessedAt.isNull(),
      );
    }

    // Фильтр по избранным
    if (base.isFavorite != null) {
      expressions.add(files.isFavorite.equals(base.isFavorite!));
    }

    // Фильтр по закрепленным
    if (base.isPinned != null) {
      expressions.add(files.isPinned.equals(base.isPinned!));
    }

    // Фильтр по архивным
    if (base.isArchived != null) {
      expressions.add(files.isArchived.equals(base.isArchived!));
    }

    // Фильтр по часто используемым
    if (base.isFrequentlyUsed != null) {
      if (base.isFrequentlyUsed!) {
        expressions.add(
          files.usedCount.isBiggerOrEqualValue(
            MainConstants.frequentlyUsedThreshold,
          ),
        );
      } else {
        expressions.add(
          files.usedCount.isSmallerThanValue(
            MainConstants.frequentlyUsedThreshold,
          ),
        );
      }
    }

    // Фильтр по удаленным
    if (base.isDeleted != null) {
      expressions.add(files.isDeleted.equals(base.isDeleted!));
    } else {
      // По умолчанию исключаем удаленные
      expressions.add(files.isDeleted.equals(false));
    }
  }

  /// Применить фильтры, специфичные для файлов
  void _applyFileSpecificFilters(
    FilesFilter filter,
    List<Expression<bool>> expressions,
  ) {
    // Фильтр по расширениям файлов
    if (filter.fileExtensions.isNotEmpty) {
      Expression<bool>? extensionExpression;
      for (final ext in filter.fileExtensions) {
        final condition = files.fileExtension.lower().equals(ext.toLowerCase());
        extensionExpression = extensionExpression == null
            ? condition
            : (extensionExpression | condition);
      }
      if (extensionExpression != null) {
        expressions.add(extensionExpression);
      }
    }

    // Фильтр по MIME типам
    if (filter.mimeTypes.isNotEmpty) {
      Expression<bool>? mimeExpression;
      for (final mime in filter.mimeTypes) {
        final condition = files.mimeType.lower().equals(mime.toLowerCase());
        mimeExpression = mimeExpression == null
            ? condition
            : (mimeExpression | condition);
      }
      if (mimeExpression != null) {
        expressions.add(mimeExpression);
      }
    }

    // Фильтр по имени файла
    if (filter.fileName != null && filter.fileName!.isNotEmpty) {
      final fileNameLower = filter.fileName!.toLowerCase();
      expressions.add(files.fileName.lower().like('%$fileNameLower%'));
    }

    // Фильтр по минимальному размеру файла
    if (filter.minFileSize != null) {
      expressions.add(files.fileSize.isBiggerOrEqualValue(filter.minFileSize!));
    }

    // Фильтр по максимальному размеру файла
    if (filter.maxFileSize != null) {
      expressions.add(
        files.fileSize.isSmallerOrEqualValue(filter.maxFileSize!),
      );
    }
  }

  /// Построить ORDER BY выражение
  List<OrderingTerm> _buildOrderBy(FilesFilter filter) {
    final orderTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderTerms.add(
      OrderingTerm(expression: files.isPinned, mode: OrderingMode.desc),
    );

    // Сортировка по указанному полю
    final sortField = filter.sortField ?? FilesSortField.modifiedAt;
    final sortDirection = filter.base.sortDirection;

    switch (sortField) {
      case FilesSortField.name:
        orderTerms.add(
          OrderingTerm(
            expression: files.name,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.fileName:
        orderTerms.add(
          OrderingTerm(
            expression: files.fileName,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.fileSize:
        orderTerms.add(
          OrderingTerm(
            expression: files.fileSize,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.fileExtension:
        orderTerms.add(
          OrderingTerm(
            expression: files.fileExtension,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.mimeType:
        orderTerms.add(
          OrderingTerm(
            expression: files.mimeType,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.createdAt:
        orderTerms.add(
          OrderingTerm(
            expression: files.createdAt,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.modifiedAt:
        orderTerms.add(
          OrderingTerm(
            expression: files.modifiedAt,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
      case FilesSortField.lastAccessed:
        orderTerms.add(
          OrderingTerm(
            expression: files.lastAccessedAt,
            mode: sortDirection == SortDirection.asc
                ? OrderingMode.asc
                : OrderingMode.desc,
          ),
        );
        break;
    }

    return orderTerms;
  }
}
