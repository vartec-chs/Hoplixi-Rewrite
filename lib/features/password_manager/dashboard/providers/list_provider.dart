import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/data_refresh_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_tab_provider.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import 'filter_providers/password_filter_provider.dart';
import 'data_refresh_trigger_provider.dart';
import '../models/filter_tab.dart';

// Константа размера страницы можно переиспользовать или сделать мапу по типу
const int kDefaultPageSize = 20;

/// Провайдер family: для каждого EntityType — свой экземпляр Notifier
final paginatedListProvider =
    AsyncNotifierProvider<PaginatedListNotifier, DashboardListState<dynamic>>(
      PaginatedListNotifier.new,
    );

class PaginatedListNotifier extends AsyncNotifier<DashboardListState<dynamic>> {
  int get pageSize {
    // можно иметь разный pageSize для разных типов, если нужно
    return kDefaultPageSize;
  }

  ProviderSubscription<PasswordsFilter>? _passwordFilterSubscription;
  ProviderSubscription<NotesFilter>? _noteFilterSubscription;
  ProviderSubscription<BankCardsFilter>? _bankCardFilterSubscription;
  ProviderSubscription<FilesFilter>? _fileFilterSubscription;
  ProviderSubscription<OtpsFilter>? _otpFilterSubscription;
  ProviderSubscription<DataRefreshState>? _passwordRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _noteRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _bankCardRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _fileRefreshSubscription;
  ProviderSubscription<DataRefreshState>? _otpRefreshSubscription;

  @override
  Future<DashboardListState<dynamic>> build() async {
    ref.listen(filterTabProvider, (prev, next) {
      if (prev != next) {
        _resetAndLoad();
      }
    });

    ref.listen(entityTypeProvider, (prev, next) {
      if (prev?.currentType != next.currentType) {
        _subscribeToTypeSpecificProviders();
        _resetAndLoad();
      }
    });

    // 3) условные слушатели фильтров / вкладок — в зависимости от типа
    _subscribeToTypeSpecificProviders();

    return _loadInitialData();
  }

  void _subscribeToTypeSpecificProviders() {
    _unsubscribeTypeSpecificProviders();
    switch (ref.read(entityTypeProvider).currentType) {
      case EntityType.password:
        _passwordFilterSubscription = ref.listen(passwordsFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _passwordRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.password)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных паролей',
              );
              _resetAndLoad();
            }
          },
        );

        break;
      case EntityType.note:
        _noteFilterSubscription = ref.listen(notesFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _noteRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.note)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных заметок',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.bankCard:
        _bankCardFilterSubscription = ref.listen(bankCardsFilterProvider, (
          prev,
          next,
        ) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _bankCardRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.bankCard)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных карточек',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.file:
        _fileFilterSubscription = ref.listen(filesFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _fileRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.file)) {
              logDebug(
                'PaginatedListNotifier: Триггер обновления данных файлов',
              );
              _resetAndLoad();
            }
          },
        );
        break;
      case EntityType.otp:
        _otpFilterSubscription = ref.listen(otpsFilterProvider, (prev, next) {
          if (prev != next) {
            _resetAndLoad();
          }
        });
        _otpRefreshSubscription = ref.listen<DataRefreshState>(
          dataRefreshTriggerProvider,
          (previous, next) {
            if (_shouldHandleRefresh(next, EntityType.otp)) {
              logDebug('PaginatedListNotifier: Триггер обновления данных OTP');
              _resetAndLoad();
            }
          },
        );
        break;
    }
  }

  void _unsubscribeTypeSpecificProviders() {
    _passwordFilterSubscription?.close();
    _passwordFilterSubscription = null;
    _noteFilterSubscription?.close();
    _noteFilterSubscription = null;
    _bankCardFilterSubscription?.close();
    _bankCardFilterSubscription = null;
    _fileFilterSubscription?.close();
    _fileFilterSubscription = null;
    _otpFilterSubscription?.close();
    _otpFilterSubscription = null;
    _passwordRefreshSubscription?.close();
    _passwordRefreshSubscription = null;
    _noteRefreshSubscription?.close();
    _noteRefreshSubscription = null;
    _bankCardRefreshSubscription?.close();
    _bankCardRefreshSubscription = null;
    _fileRefreshSubscription?.close();
    _fileRefreshSubscription = null;
    _otpRefreshSubscription?.close();
    _otpRefreshSubscription = null;
  }

  bool _shouldHandleRefresh(DataRefreshState state, EntityType type) {
    return state.entityType == null || state.entityType == type;
  }

  /// Выбор DAO по type — вынеси в отдельную функцию/мапу
  Future<FilterDao<dynamic, dynamic>> _daoForType() {
    switch (ref.read(entityTypeProvider).currentType) {
      case EntityType.password:
        return ref.read(passwordFilterDaoProvider.future);
      case EntityType.note:
        return ref.read(noteFilterDaoProvider.future);
      case EntityType.bankCard:
        return ref.read(bankCardFilterDaoProvider.future);
      case EntityType.file:
        return ref.read(fileFilterDaoProvider.future);
      case EntityType.otp:
        return ref.read(otpFilterDaoProvider.future);
    }
  }

  /// Выбор CRUD DAO по type для обновлений
  Future<BaseMainEntityDao> _crudDaoForType() {
    switch (ref.read(entityTypeProvider).currentType) {
      case EntityType.password:
        return ref.read(passwordDaoProvider.future);
      case EntityType.note:
        return ref.read(noteDaoProvider.future);
      case EntityType.bankCard:
        return ref.read(bankCardDaoProvider.future);
      case EntityType.file:
        return ref.read(fileDaoProvider.future);
      case EntityType.otp:
        return ref.read(otpDaoProvider.future);
    }
  }

  /// Если нужен специфичный фильтр (например PasswordFilter) — строим его условно.
  /// Возвращаем общий BaseFilter или конкретный фильтр для DAO.getFilteredX
  dynamic _buildFilter({int page = 1}) {
    final limit = pageSize;
    final offset = (page - 1) * limit;
    final currentTab = ref.read(filterTabProvider);
    final tabFilter = _getTabFilter(currentTab);

    switch (ref.read(entityTypeProvider).currentType) {
      case EntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        final base = passwordFilter.base.copyWith(
          isFavorite: tabFilter.isFavorite ?? passwordFilter.base.isFavorite,
          isArchived: tabFilter.isArchived ?? passwordFilter.base.isArchived,
          isDeleted: tabFilter.isDeleted ?? passwordFilter.base.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              passwordFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return passwordFilter.copyWith(base: base);
      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        final base = notesFilter.base.copyWith(
          isFavorite: tabFilter.isFavorite ?? notesFilter.base.isFavorite,
          isArchived: tabFilter.isArchived ?? notesFilter.base.isArchived,
          isDeleted: tabFilter.isDeleted ?? notesFilter.base.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? notesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return notesFilter.copyWith(base: base);
      case EntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        final base = bankCardsFilter.base.copyWith(
          isFavorite: tabFilter.isFavorite ?? bankCardsFilter.base.isFavorite,
          isArchived: tabFilter.isArchived ?? bankCardsFilter.base.isArchived,
          isDeleted: tabFilter.isDeleted ?? bankCardsFilter.base.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ??
              bankCardsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return bankCardsFilter.copyWith(base: base);
      case EntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        final base = filesFilter.base.copyWith(
          isFavorite: tabFilter.isFavorite ?? filesFilter.base.isFavorite,
          isArchived: tabFilter.isArchived ?? filesFilter.base.isArchived,
          isDeleted: tabFilter.isDeleted ?? filesFilter.base.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? filesFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return filesFilter.copyWith(base: base);
      case EntityType.otp:
        final otpsFilter = ref.read(otpsFilterProvider);
        final base = otpsFilter.base.copyWith(
          isFavorite: tabFilter.isFavorite ?? otpsFilter.base.isFavorite,
          isArchived: tabFilter.isArchived ?? otpsFilter.base.isArchived,
          isDeleted: tabFilter.isDeleted ?? otpsFilter.base.isDeleted,
          isFrequentlyUsed:
              tabFilter.isFrequentlyUsed ?? otpsFilter.base.isFrequentlyUsed,
          limit: limit,
          offset: offset,
        );
        return otpsFilter.copyWith(base: base);
    }
  }

  BaseFilter _getTabFilter(FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return BaseFilter.create();
      case FilterTab.favorites:
        return BaseFilter.create(isFavorite: true);
      case FilterTab.frequent:
        return BaseFilter.create(isFrequentlyUsed: true);
      case FilterTab.archived:
        return BaseFilter.create(isArchived: true);
      case FilterTab.delete:
        return BaseFilter.create(isDeleted: true);
    }
  }

  Future<DashboardListState<dynamic>> _loadInitialData() async {
    try {
      // Получаем DAO и делаем тестовую проверку (по аналогии с твоим кодом)
      final dao = await _daoForType();

      // Строим фильтр и подгружаем первую страницу
      final filter = _buildFilter(page: 1);

      // Предполагаю, что у DAO есть getFiltered<type> и countFiltered<type>.
      // Для унификации можно в DAO сделать общий метод getFiltered(filter) возвращающий List<dynamic>.
      final items = await dao.getFiltered(filter);
      final totalCount = await dao.countFiltered(filter);

      return DashboardListState<dynamic>(
        items: items,
        isLoading: false,
        hasMore: items.length >= pageSize && items.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e) {
      return DashboardListState(error: e.toString());
    }
  }

  /// loadMore аналогично твоему
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    try {
      state = AsyncValue.data(current.copyWith(isLoadingMore: true));
      final nextPage = current.currentPage + 1;
      final filter = _buildFilter(page: nextPage);
      final dao = await _daoForType();
      final newItems = await dao.getFiltered(filter);

      final all = [...current.items, ...newItems];
      final hasMore =
          newItems.length >= pageSize && all.length < current.totalCount;

      state = AsyncValue.data(
        current.copyWith(
          items: all,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  /// refresh
  Future<void> refresh() async {
    final cur = state.value;
    if (cur != null) {
      state = AsyncValue.data(cur.copyWith(isLoading: true));
      try {
        final newState = await _loadInitialData();
        state = AsyncValue.data(newState);
      } catch (e) {
        state = AsyncValue.data(
          cur.copyWith(isLoading: false, error: e.toString()),
        );
      }
    } else {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadInitialData);
    }
  }

  /// Примеры операций (toggleFavorite / delete) — делаем через _serviceForType и адаптацию DTO
  Future<void> toggleFavorite(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final newFav = !(item.isFavorite ?? false);

    final updated = [...cur.items];
    updated[index] = item.copyWith(isFavorite: newFav);

    state = AsyncValue.data(cur.copyWith(items: updated));

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.toggleFavorite(id, newFav);

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      } else {
        if (ref.read(filterTabProvider) == FilterTab.favorites && !newFav) {
          // Если мы на вкладке "Избранное" и элемент снят с избранного — удаляем его из списка
          updated.removeAt(index);
          state = AsyncValue.data(
            cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
          );
        }
      }
    } catch (e) {
      // откат
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> togglePin(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final newPin = !(item.isPinned ?? false);

    final updated = [...cur.items];
    updated[index] = item.copyWith(isPinned: newPin);

    state = AsyncValue.data(cur.copyWith(items: updated));

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.togglePin(id, newPin);

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              ref.read(entityTypeProvider).currentType,
              entityId: id,
            );
      }
    } catch (e) {
      // откат
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> toggleArchive(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final newArchive = !(item.isArchived ?? false);

    final updated = [...cur.items];
    updated[index] = item.copyWith(isArchived: newArchive);

    state = AsyncValue.data(cur.copyWith(items: updated));

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.toggleArchive(id, newArchive);

      if (!success) {
        // откат
        updated[index] = item;
        state = AsyncValue.data(cur.copyWith(items: updated));
      }
    } catch (e) {
      // откат
      updated[index] = item;
      state = AsyncValue.data(cur.copyWith(items: updated));
    }
  }

  Future<void> delete(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.softDelete(id);

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
        );
      } else {
        // Триггерим обновление данных
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              ref.read(entityTypeProvider).currentType,
              entityId: id,
            );
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  Future<void> restoreFromDeleted(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.restoreFromDeleted(id);

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
        );
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              ref.read(entityTypeProvider).currentType,
              entityId: id,
            );
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  Future<void> permanentDelete(String id) async {
    final cur = state.value;
    if (cur == null) return;

    final index = cur.items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = cur.items[index];
    final updated = [...cur.items];
    updated.removeAt(index);

    state = AsyncValue.data(
      cur.copyWith(items: updated, totalCount: cur.totalCount - 1),
    );

    try {
      final dao = await _crudDaoForType();
      bool success = false;
      success = await dao.permanentDelete(id);

      if (!success) {
        // откат
        updated.insert(index, item);
        state = AsyncValue.data(
          cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
        );
      } else {
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityDelete(
              ref.read(entityTypeProvider).currentType,
              entityId: id,
            );
      }
    } catch (e) {
      // откат
      updated.insert(index, item);
      state = AsyncValue.data(
        cur.copyWith(items: updated, totalCount: cur.totalCount + 1),
      );
    }
  }

  void _resetAndLoad() {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }
}
