import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/notes_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'note_filter_dao.g.dart';

@DriftAccessor(tables: [Notes, Categories, NotesTags])
class NoteFilterDao extends DatabaseAccessor<MainStore>
    with _$NoteFilterDaoMixin {
  NoteFilterDao(super.db);

  /// Основной метод для получения отфильтрованных заметок
  Future<List<NoteCardDto>> getFilteredNotes(NotesFilter filter) async {
    // Создаем базовый запрос с join к категориям
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ]);

    // Применяем все фильтры
    query.where(_buildWhereExpression(filter));

    // Применяем сортировку
    query.orderBy(_buildOrderBy(filter));

    // Применяем limit и offset
    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    // Выполняем запрос и маппим результаты
    final results = await query.get();

    return results.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: note.id,
        title: note.title,
        description: note.description,
        categoryName: category?.name,
        isFavorite: note.isFavorite,
        isPinned: note.isPinned,
        usedCount: note.usedCount,
        modifiedAt: note.modifiedAt,
      );
    }).toList();
  }

  /// Строит WHERE выражение на основе всех фильтров
  Expression<bool> _buildWhereExpression(NotesFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Применяем базовые фильтры
    expression = expression & _applyBaseFilters(filter.base);

    // Применяем специфичные фильтры для заметок
    expression = expression & _applyNoteSpecificFilters(filter);

    return expression;
  }

  /// Применяет базовые фильтры из BaseFilter
  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expression = const Constant(true);

    // Поисковый запрос по нескольким полям
    if (base.query.isNotEmpty) {
      final query = base.query.toLowerCase();
      expression =
          expression &
          (notes.title.lower().like('%$query%') |
              notes.description.lower().like('%$query%') |
              notes.content.lower().like('%$query%'));
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expression = expression & notes.categoryId.isIn(base.categoryIds);
    }

    // Фильтр по тегам (требует подзапрос)
    if (base.tagIds.isNotEmpty) {
      // Используем EXISTS для проверки наличия тегов
      final tagExists = existsQuery(
        select(notesTags)..where(
          (nt) => nt.noteId.equalsExp(notes.id) & nt.tagId.isIn(base.tagIds),
        ),
      );

      expression = expression & tagExists;
    }

    // Булевы флаги
    if (base.isFavorite != null) {
      expression = expression & notes.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expression = expression & notes.isArchived.equals(base.isArchived!);
    }

    if (base.isDeleted != null) {
      expression = expression & notes.isDeleted.equals(base.isDeleted!);
    }

    if (base.isPinned != null) {
      expression = expression & notes.isPinned.equals(base.isPinned!);
    }

    if (base.hasNotes != null) {
      // Для заметок этот фильтр не применим, так как все записи - это заметки
      // Но оставляем для совместимости с BaseFilter
    }

    // Фильтр по частоте использования
    if (base.isFrequentlyUsed != null) {
      expression =
          expression &
          (base.isFrequentlyUsed!
              ? notes.usedCount.isBiggerOrEqualValue(
                  MainConstants.frequentlyUsedThreshold,
                )
              : notes.usedCount.isSmallerThanValue(
                  MainConstants.frequentlyUsedThreshold,
                ));
    }

    // Диапазоны дат создания
    if (base.createdAfter != null) {
      expression =
          expression & notes.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }

    if (base.createdBefore != null) {
      expression =
          expression &
          notes.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }

    // Диапазоны дат модификации
    if (base.modifiedAfter != null) {
      expression =
          expression &
          notes.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }

    if (base.modifiedBefore != null) {
      expression =
          expression &
          notes.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }

    // Диапазоны дат последнего доступа
    if (base.lastAccessedAfter != null) {
      expression =
          expression &
          notes.lastAccessedAt.isBiggerOrEqualValue(base.lastAccessedAfter!);
    }

    if (base.lastAccessedBefore != null) {
      expression =
          expression &
          notes.lastAccessedAt.isSmallerOrEqualValue(base.lastAccessedBefore!);
    }

    // Диапазоны счетчика использований
    if (base.minUsedCount != null) {
      expression =
          expression & notes.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }

    if (base.maxUsedCount != null) {
      expression =
          expression &
          notes.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    return expression;
  }

  /// Применяет специфичные фильтры для заметок
  Expression<bool> _applyNoteSpecificFilters(NotesFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Фильтр по заголовку
    if (filter.title != null) {
      expression =
          expression &
          notes.title.lower().like('%${filter.title!.toLowerCase()}%');
    }

    // Фильтр по содержимому
    if (filter.content != null) {
      expression =
          expression &
          notes.content.lower().like('%${filter.content!.toLowerCase()}%');
    }

    // Наличие описания
    if (filter.hasDescription != null) {
      expression =
          expression &
          (filter.hasDescription!
              ? notes.description.isNotNull()
              : notes.description.isNull());
    }

    // Наличие deltaJson (Quill формат)
    if (filter.hasDeltaJson != null) {
      expression =
          expression &
          (filter.hasDeltaJson!
              ? notes.deltaJson.isNotNull()
              : notes.deltaJson.isNull());
    }

    // Фильтр по длине контента
    if (filter.minContentLength != null) {
      expression =
          expression &
          notes.content.length.isBiggerOrEqualValue(filter.minContentLength!);
    }

    if (filter.maxContentLength != null) {
      expression =
          expression &
          notes.content.length.isSmallerOrEqualValue(filter.maxContentLength!);
    }

    return expression;
  }

  /// Строит список OrderingTerm для сортировки
  List<OrderingTerm> _buildOrderBy(NotesFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: notes.isPinned, mode: OrderingMode.desc),
    );

    // Основная сортировка по указанному полю
    if (filter.sortField != null) {
      final mode = filter.base.sortDirection == SortDirection.asc
          ? OrderingMode.asc
          : OrderingMode.desc;

      switch (filter.sortField!) {
        case NotesSortField.title:
          orderingTerms.add(OrderingTerm(expression: notes.title, mode: mode));
          break;
        case NotesSortField.description:
          orderingTerms.add(
            OrderingTerm(expression: notes.description, mode: mode),
          );
          break;
        case NotesSortField.contentLength:
          // Сортировка по длине контента
          orderingTerms.add(
            OrderingTerm(expression: notes.content.length, mode: mode),
          );
          break;
        case NotesSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.createdAt, mode: mode),
          );
          break;
        case NotesSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.modifiedAt, mode: mode),
          );
          break;
        case NotesSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: notes.lastAccessedAt, mode: mode),
          );
          break;
      }
    } else {
      // Сортировка по умолчанию - по дате модификации
      orderingTerms.add(
        OrderingTerm(
          expression: notes.modifiedAt,
          mode: filter.base.sortDirection == SortDirection.asc
              ? OrderingMode.asc
              : OrderingMode.desc,
        ),
      );
    }

    return orderingTerms;
  }
}
