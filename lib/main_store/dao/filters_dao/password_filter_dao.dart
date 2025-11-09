import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/passwords_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'password_filter_dao.g.dart';

@DriftAccessor(tables: [Passwords, Categories, PasswordsTags])
class PasswordFilterDao extends DatabaseAccessor<MainStore>
    with _$PasswordFilterDaoMixin {
  PasswordFilterDao(super.db);

  /// Основной метод для получения отфильтрованных паролей
  Future<List<PasswordCardDto>> getFilteredPasswords(
    PasswordsFilter filter,
  ) async {
    // Создаем базовый запрос с join к категориям
    final query = select(passwords).join([
      leftOuterJoin(categories, categories.id.equalsExp(passwords.categoryId)),
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
      final password = row.readTable(passwords);
      final category = row.readTableOrNull(categories);

      return PasswordCardDto(
        id: password.id,
        name: password.name,
        login: password.login,
        email: password.email,
        url: password.url,
        categoryName: category?.name,
        isFavorite: password.isFavorite,
        isPinned: password.isPinned,
        usedCount: password.usedCount,
        modifiedAt: password.modifiedAt,
      );
    }).toList();
  }

  /// Строит WHERE выражение на основе всех фильтров
  Expression<bool> _buildWhereExpression(PasswordsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Применяем базовые фильтры
    expression = expression & _applyBaseFilters(filter.base);

    // Применяем специфичные фильтры для паролей
    expression = expression & _applyPasswordSpecificFilters(filter);

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
          (passwords.name.lower().like('%$query%') |
              passwords.login.lower().like('%$query%') |
              passwords.email.lower().like('%$query%') |
              passwords.url.lower().like('%$query%') |
              passwords.description.lower().like('%$query%') |
              passwords.notes.lower().like('%$query%'));
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expression = expression & passwords.categoryId.isIn(base.categoryIds);
    }

    // Фильтр по тегам (требует подзапрос)
    if (base.tagIds.isNotEmpty) {
      // Используем EXISTS для проверки наличия тегов
      final tagExists = existsQuery(
        select(passwordsTags)..where(
          (pt) =>
              pt.passwordId.equalsExp(passwords.id) &
              pt.tagId.isIn(base.tagIds),
        ),
      );

      expression = expression & tagExists;
    }

    // Булевы флаги
    if (base.isFavorite != null) {
      expression = expression & passwords.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expression = expression & passwords.isArchived.equals(base.isArchived!);
    }

    if (base.isDeleted != null) {
      expression = expression & passwords.isDeleted.equals(base.isDeleted!);
    }

    if (base.isPinned != null) {
      expression = expression & passwords.isPinned.equals(base.isPinned!);
    }

    if (base.hasNotes != null) {
      expression =
          expression &
          (base.hasNotes!
              ? passwords.notes.isNotNull()
              : passwords.notes.isNull());
    }

    // Фильтр по частоте использования
    if (base.isFrequentlyUsed != null) {
      expression =
          expression &
          (base.isFrequentlyUsed!
              ? passwords.usedCount.isBiggerOrEqualValue(
                  MainConstants.frequentlyUsedThreshold,
                )
              : passwords.usedCount.isSmallerThanValue(
                  MainConstants.frequentlyUsedThreshold,
                ));
    }

    // Диапазоны дат создания
    if (base.createdAfter != null) {
      expression =
          expression &
          passwords.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }

    if (base.createdBefore != null) {
      expression =
          expression &
          passwords.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }

    // Диапазоны дат модификации
    if (base.modifiedAfter != null) {
      expression =
          expression &
          passwords.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }

    if (base.modifiedBefore != null) {
      expression =
          expression &
          passwords.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }

    // Диапазоны дат последнего доступа
    if (base.lastAccessedAfter != null) {
      expression =
          expression &
          passwords.lastAccessedAt.isBiggerOrEqualValue(
            base.lastAccessedAfter!,
          );
    }

    if (base.lastAccessedBefore != null) {
      expression =
          expression &
          passwords.lastAccessedAt.isSmallerOrEqualValue(
            base.lastAccessedBefore!,
          );
    }

    // Диапазоны счетчика использований
    if (base.minUsedCount != null) {
      expression =
          expression &
          passwords.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }

    if (base.maxUsedCount != null) {
      expression =
          expression &
          passwords.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    return expression;
  }

  /// Применяет специфичные фильтры для паролей
  Expression<bool> _applyPasswordSpecificFilters(PasswordsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Фильтр по имени
    if (filter.name != null) {
      expression =
          expression &
          passwords.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    // Фильтр по логину
    if (filter.login != null) {
      expression =
          expression &
          passwords.login.lower().like('%${filter.login!.toLowerCase()}%');
    }

    // Фильтр по email
    if (filter.email != null) {
      expression =
          expression &
          passwords.email.lower().like('%${filter.email!.toLowerCase()}%');
    }

    // Фильтр по URL
    if (filter.url != null) {
      expression =
          expression &
          passwords.url.lower().like('%${filter.url!.toLowerCase()}%');
    }

    // Наличие описания
    if (filter.hasDescription != null) {
      expression =
          expression &
          (filter.hasDescription!
              ? passwords.description.isNotNull()
              : passwords.description.isNull());
    }

    // Наличие заметок
    if (filter.hasNotes != null) {
      expression =
          expression &
          (filter.hasNotes!
              ? passwords.notes.isNotNull()
              : passwords.notes.isNull());
    }

    // Наличие URL
    if (filter.hasUrl != null) {
      expression =
          expression &
          (filter.hasUrl! ? passwords.url.isNotNull() : passwords.url.isNull());
    }

    // Наличие логина
    if (filter.hasLogin != null) {
      expression =
          expression &
          (filter.hasLogin!
              ? passwords.login.isNotNull()
              : passwords.login.isNull());
    }

    // Наличие email
    if (filter.hasEmail != null) {
      expression =
          expression &
          (filter.hasEmail!
              ? passwords.email.isNotNull()
              : passwords.email.isNull());
    }

    return expression;
  }

  /// Строит список OrderingTerm для сортировки
  List<OrderingTerm> _buildOrderBy(PasswordsFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: passwords.isPinned, mode: OrderingMode.desc),
    );

    // Основная сортировка по указанному полю
    if (filter.sortField != null) {
      final mode = filter.base.sortDirection == SortDirection.asc
          ? OrderingMode.asc
          : OrderingMode.desc;

      switch (filter.sortField!) {
        case PasswordsSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: passwords.name, mode: mode),
          );
          break;
        case PasswordsSortField.login:
          orderingTerms.add(
            OrderingTerm(expression: passwords.login, mode: mode),
          );
          break;
        case PasswordsSortField.email:
          orderingTerms.add(
            OrderingTerm(expression: passwords.email, mode: mode),
          );
          break;
        case PasswordsSortField.url:
          orderingTerms.add(
            OrderingTerm(expression: passwords.url, mode: mode),
          );
          break;
        case PasswordsSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.createdAt, mode: mode),
          );
          break;
        case PasswordsSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.modifiedAt, mode: mode),
          );
          break;
        case PasswordsSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: passwords.lastAccessedAt, mode: mode),
          );
          break;
      }
    } else {
      // Сортировка по умолчанию - по дате модификации
      orderingTerms.add(
        OrderingTerm(
          expression: passwords.modifiedAt,
          mode: filter.base.sortDirection == SortDirection.asc
              ? OrderingMode.asc
              : OrderingMode.desc,
        ),
      );
    }

    return orderingTerms;
  }
}
