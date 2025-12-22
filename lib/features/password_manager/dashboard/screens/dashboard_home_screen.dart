import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_builders.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen> {
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  final GlobalKey<SliverAnimatedGridState> _gridKey = GlobalKey();
  late final ScrollController _scrollController;

  // Локальный список для отображения и вычисления разницы (Diff)
  List<BaseCardDto> _displayedItems = [];
  bool _isClearing = false;

  // Очередь обновлений
  List<BaseCardDto>? _pendingNewItems;
  bool _isUpdating = false;

  static const _kScrollThreshold = 200.0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Инициализация начальными данными после построения кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Небольшая задержка, чтобы убедиться, что SliverAnimatedList смонтирован
      // и готов к анимации вставки элементов
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final state = ref.read(paginatedListProvider).value;
        if (state != null && state.items.isNotEmpty) {
          _updateList(state.items);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _kScrollThreshold) {
      _tryLoadMore();
    }
  }

  void _tryLoadMore() {
    // Дебаунс для предотвращения частых вызовов
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      final state = ref.read(paginatedListProvider).value;
      if (state != null &&
          !state.isLoadingMore &&
          state.hasMore &&
          !state.isLoading) {
        ref.read(paginatedListProvider.notifier).loadMore();
      }
    });
  }

  /// Основной метод обновления списка с анимациями
  void _updateList(List<BaseCardDto> newItems, {bool animate = true}) {
    _pendingNewItems = newItems;
    if (_isUpdating) return;
    _processUpdateQueue(animate: animate);
  }

  Future<void> _processUpdateQueue({bool animate = true}) async {
    _isUpdating = true;
    while (_pendingNewItems != null) {
      final items = _pendingNewItems!;
      _pendingNewItems = null;

      // Выполняем обновление
      _performDiffAndUpdate(items, animate: animate);

      // Даем UI обновиться, если есть еще задачи
      if (_pendingNewItems != null) {
        await Future.delayed(Duration.zero);
      }
    }
    _isUpdating = false;
  }

  void _performDiffAndUpdate(
    List<BaseCardDto> newItems, {
    bool animate = true,
  }) {
    final viewMode = ref.read(currentViewModeProvider);
    final listState = _listKey.currentState;
    final gridState = _gridKey.currentState;

    // Если ключи не готовы или анимация отключена, просто обновляем список
    if (!animate ||
        (viewMode == ViewMode.list && listState == null) ||
        (viewMode == ViewMode.grid && gridState == null)) {
      setState(() {
        _displayedItems = List.from(newItems);
      });
      return;
    }

    // Оптимизация: Set для быстрого поиска удаляемых элементов O(1)
    final newItemIds = newItems.map((e) => e.id).toSet();

    // 1. Удаление элементов (идем с конца, чтобы не сбить индексы)
    bool itemsRemoved = false;
    for (int i = _displayedItems.length - 1; i >= 0; i--) {
      final item = _displayedItems[i];
      if (!newItemIds.contains(item.id)) {
        final removedItem = _displayedItems.removeAt(i);
        itemsRemoved = true;

        if (viewMode == ViewMode.list) {
          listState?.removeItem(
            i,
            (context, animation) =>
                _buildRemovedItem(removedItem, context, animation, viewMode),
            duration: kStatusSwitchDuration,
          );
        } else {
          gridState?.removeItem(
            i,
            (context, animation) =>
                _buildRemovedItem(removedItem, context, animation, viewMode),
            duration: kStatusSwitchDuration,
          );
        }
      }
    }

    if (itemsRemoved && newItems.isEmpty) {
      _isClearing = true;
      Timer(kStatusSwitchDuration, () {
        if (mounted) {
          setState(() {
            _isClearing = false;
          });
        }
      });
    }

    // Оптимизация: Set для проверки существования элементов O(1)
    // Используем snapshot оставшихся элементов, чтобы знать, что искать
    final displayedIds = _displayedItems.map((e) => e.id).toSet();

    // 2. Вставка новых элементов
    for (int i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];

      // Проверяем, совпадает ли элемент на текущей позиции
      if (i < _displayedItems.length && _displayedItems[i].id == newItem.id) {
        // Элемент на своем месте - просто обновляем данные
        _displayedItems[i] = newItem;
        continue;
      }

      // Если элемента нет на текущей позиции, проверяем, есть ли он вообще в списке
      if (displayedIds.contains(newItem.id)) {
        // Элемент есть, но смещен (reordering). Ищем его реальную позицию.
        // Поиск начинается с i, так как все до i уже обработаны и совпадают
        final currentIndex = _displayedItems.indexWhere(
          (e) => e.id == newItem.id,
          i,
        );

        if (currentIndex != -1) {
          final item = _displayedItems.removeAt(currentIndex);

          // Симулируем перемещение: удаляем со старой позиции с анимацией
          if (viewMode == ViewMode.list) {
            listState?.removeItem(
              currentIndex,
              (context, animation) =>
                  _buildRemovedItem(item, context, animation, viewMode),
              duration: kStatusSwitchDuration,
            );
          } else {
            gridState?.removeItem(
              currentIndex,
              (context, animation) =>
                  _buildRemovedItem(item, context, animation, viewMode),
              duration: kStatusSwitchDuration,
            );
          }

          _displayedItems.insert(i, item);
          // Обновляем данные
          _displayedItems[i] = newItem;

          // Симулируем перемещение: вставляем на новую позицию с анимацией
          if (viewMode == ViewMode.list) {
            listState?.insertItem(i, duration: kStatusSwitchDuration);
          } else {
            gridState?.insertItem(i, duration: kStatusSwitchDuration);
          }
        }
      } else {
        // Элемента нет в списке - вставляем
        _displayedItems.insert(i, newItem);
        if (viewMode == ViewMode.list) {
          listState?.insertItem(i, duration: kStatusSwitchDuration);
        } else {
          gridState?.insertItem(i, duration: kStatusSwitchDuration);
        }
      }
    }

    // Обновляем UI для отображения изменений внутри элементов
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения провайдера списка
    ref.listen<
      AsyncValue<DashboardListState<BaseCardDto>>
    >(paginatedListProvider, (prev, next) {
      next.whenData((state) {
        // Обновляем список после построения кадра, чтобы избежать мутации во время layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // Обновляем список при изменении данных
          // Если это первая загрузка (список был пуст), даем время на построение SliverAnimatedList
          if (_displayedItems.isEmpty && state.items.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _updateList(state.items);
            });
          } else {
            _updateList(state.items);
          }
        });
      });
    });

    final entityType = ref.watch(entityTypeProvider).currentType;
    final viewMode = ref.watch(currentViewModeProvider);
    final asyncValue = ref.watch(paginatedListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedListProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            DashboardSliverAppBar(
              expandedHeight: 178.0,
              collapsedHeight: 60.0,
              pinned: true,
              floating: false,
              snap: false,
              showEntityTypeSelector: true,
            ),
            SliverToBoxAdapter(
              child: DashboardListToolBar(
                entityType: entityType,
                viewMode: viewMode,
                listState: asyncValue,
              ),
            ),
            DashboardHomeBuilders.buildContentSliver(
              context: context,
              ref: ref,
              entityType: entityType,
              viewMode: viewMode,
              asyncValue: asyncValue,
              displayedItems: _displayedItems,
              isClearing: _isClearing,
              listKey: _listKey,
              gridKey: _gridKey,
              callbacks: DashboardCardCallbacks.fromRefWithLocalRemove(
                ref,
                _removeItemLocally,
              ),
              onInvalidate: () => ref.invalidate(paginatedListProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovedItem(
    BaseCardDto item,
    BuildContext context,
    Animation<double> animation,
    ViewMode viewMode,
  ) {
    return DashboardHomeBuilders.buildRemovedItem(
      context: context,
      ref: ref,
      item: item,
      animation: animation,
      viewMode: viewMode,
      callbacks: DashboardCardCallbacks.fromRefWithLocalRemove(
        ref,
        _removeItemLocally,
      ),
    );
  }

  /// Локальное удаление элемента без анимации (для Dismissible)
  void _removeItemLocally(String id) {
    setState(() {
      _displayedItems.removeWhere((item) => item.id == id);
    });
  }
}
