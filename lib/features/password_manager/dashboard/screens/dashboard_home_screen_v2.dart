import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password_cards.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:sliver_tools/sliver_tools.dart';

const _kStatusSwitchDuration = Duration(milliseconds: 180);

class DashboardHomeScreenV2 extends ConsumerStatefulWidget {
  const DashboardHomeScreenV2({super.key});

  @override
  ConsumerState<DashboardHomeScreenV2> createState() =>
      _DashboardHomeScreenV2State();
}

class _DashboardHomeScreenV2State extends ConsumerState<DashboardHomeScreenV2> {
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
            duration: _kStatusSwitchDuration,
          );
        } else {
          gridState?.removeItem(
            i,
            (context, animation) =>
                _buildRemovedItem(removedItem, context, animation, viewMode),
            duration: _kStatusSwitchDuration,
          );
        }
      }
    }

    if (itemsRemoved && newItems.isEmpty) {
      _isClearing = true;
      Timer(_kStatusSwitchDuration, () {
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
              duration: _kStatusSwitchDuration,
            );
          } else {
            gridState?.removeItem(
              currentIndex,
              (context, animation) =>
                  _buildRemovedItem(item, context, animation, viewMode),
              duration: _kStatusSwitchDuration,
            );
          }

          _displayedItems.insert(i, item);
          // Обновляем данные
          _displayedItems[i] = newItem;

          // Симулируем перемещение: вставляем на новую позицию с анимацией
          if (viewMode == ViewMode.list) {
            listState?.insertItem(i, duration: _kStatusSwitchDuration);
          } else {
            gridState?.insertItem(i, duration: _kStatusSwitchDuration);
          }
        }
      } else {
        // Элемента нет в списке - вставляем
        _displayedItems.insert(i, newItem);
        if (viewMode == ViewMode.list) {
          listState?.insertItem(i, duration: _kStatusSwitchDuration);
        } else {
          gridState?.insertItem(i, duration: _kStatusSwitchDuration);
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
            _buildContentSliver(entityType, viewMode, asyncValue),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(
    EntityType entityType,
    ViewMode viewMode,
    AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
  ) {
    // Определяем состояние для отображения статуса (Empty/Error/Loading)
    final hasItems = _displayedItems.isNotEmpty;

    // Если есть элементы, сразу возвращаем список, чтобы избежать лишних перерисовок статуса
    if (hasItems) {
      return _buildAnimatedListOrGrid(entityType, viewMode, asyncValue.value);
    }

    final providerHasItems = asyncValue.value?.items.isNotEmpty ?? false;

    final isInitialLoading = asyncValue.isLoading && !hasItems;
    final isError = asyncValue.hasError && !hasItems;

    // Показываем статус, если нет локальных элементов и не идет очистка
    final showStatus = !hasItems && !_isClearing;

    Widget? statusSliver;
    if (showStatus) {
      if (isInitialLoading) {
        statusSliver = const SliverFillRemaining(
          key: ValueKey('loading'),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (isError) {
        statusSliver = _buildErrorSliver(
          asyncValue.error!,
          key: const ValueKey('error'),
        );
      } else if (!providerHasItems) {
        // Данных нет ни локально, ни в провайдере -> Пусто
        statusSliver = _buildEmptyState(
          entityType,
          key: const ValueKey('empty'),
        );
      } else {
        // Данные есть в провайдере, но еще не отображены (идет задержка) -> Загрузка
        statusSliver = const SliverFillRemaining(
          key: ValueKey('loading'),
          child: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      statusSliver = const SliverToBoxAdapter(
        key: ValueKey('none'),
        child: SizedBox.shrink(),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // Список всегда в дереве, чтобы избежать Duplicate GlobalKey при анимациях
        _buildAnimatedListOrGrid(entityType, viewMode, asyncValue.value),
        // Статус (загрузка, ошибка, пусто) анимируется отдельно
        SliverAnimatedSwitcher(
          duration: _kStatusSwitchDuration,
          child: statusSliver,
        ),
        // statusSliver,
      ],
    );
  }

  Widget _buildAnimatedListOrGrid(
    EntityType entityType,
    ViewMode viewMode,
    DashboardListState<BaseCardDto>? state, {
    Key? key,
  }) {
    final hasMore = state?.hasMore ?? false;
    final isLoadingMore = state?.isLoadingMore ?? false;

    Widget listSliver;
    if (viewMode == ViewMode.list) {
      listSliver = SliverAnimatedList(
        key: _listKey,
        initialItemCount: _displayedItems.length,
        itemBuilder: (context, index, animation) {
          if (index >= _displayedItems.length) return const SizedBox.shrink();
          return _buildItemTransition(
            context,
            _displayedItems[index],
            animation,
            viewMode,
            entityType,
          );
        },
      );
    } else {
      // В Grid режиме используем SliverPadding, но если элементов нет - скрываем паддинг,
      // чтобы не занимать место (хотя SliverAnimatedGrid с 0 элементов и так пуст, но паддинг останется)
      // Однако, при анимации удаления паддинг нужен.
      listSliver = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverAnimatedGrid(
          key: _gridKey,
          initialItemCount: _displayedItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index, animation) {
            if (index >= _displayedItems.length) return const SizedBox.shrink();
            return _buildItemTransition(
              context,
              _displayedItems[index],
              animation,
              viewMode,
              entityType,
            );
          },
        ),
      );
    }

    return SliverMainAxisGroup(
      key: key,
      slivers: [listSliver, _buildFooter(hasMore, isLoadingMore)],
    );
  }

  Widget _buildItemTransition(
    BuildContext context,
    BaseCardDto item,
    Animation<double> animation,
    ViewMode viewMode,
    EntityType entityType,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: viewMode == ViewMode.list
            ? _buildListCardFor(entityType, item)
            : _buildGridCardFor(entityType, item),
      ),
    );
  }

  Widget _buildRemovedItem(
    BaseCardDto item,
    BuildContext context,
    Animation<double> animation,
    ViewMode viewMode,
  ) {
    // Для удаленного элемента нам нужно знать его тип, но он может быть уже недоступен в провайдере
    // Используем текущий тип из провайдера (предполагаем, что тип сущности не меняется мгновенно при удалении)
    final entityType = ref.read(entityTypeProvider).currentType;

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: viewMode == ViewMode.list
            ? _buildListCardFor(entityType, item, isDismissible: false)
            : _buildGridCardFor(entityType, item),
      ),
    );
  }

  Widget _buildFooter(bool hasMore, bool isLoadingMore) {
    if (isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (!hasMore && _displayedItems.isNotEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Больше нет данных',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox(height: 8));
  }

  Widget _buildEmptyState(EntityType entityType, {Key? key}) {
    return SliverFillRemaining(
      key: key,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(entityType.icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Нет данных', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Добавьте первый элемент',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver(Object err, {Key? key}) {
    return SliverFillRemaining(
      key: key,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(paginatedListProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Builders for Cards ---

  Widget _buildListCardFor(
    EntityType type,
    BaseCardDto item, {
    bool isDismissible = true,
  }) {
    Widget card;
    switch (type) {
      case EntityType.password:
        if (item is! PasswordCardDto) return const SizedBox.shrink();
        card = PasswordListCard(
          password: item,
          onToggleFavorite: () => _onToggleFavorite(item.id),
          onTogglePin: () => _onTogglePin(item.id),
          onToggleArchive: () => _onToggleArchive(item.id),
          onDelete: () => _onDelete(item.id, item.isDeleted),
          onRestore: () => _onRestore(item.id),
        );
        break;
      case EntityType.note:
        card = const Card(child: ListTile(title: Text('Note TODO')));
        break;
      case EntityType.bankCard:
        card = const Card(child: ListTile(title: Text('BankCard TODO')));
        break;
      case EntityType.file:
        card = const Card(child: ListTile(title: Text('File TODO')));
        break;
      case EntityType.otp:
        card = const Card(child: ListTile(title: Text('OTP TODO')));
        break;
    }

    if (!isDismissible) return card;

    return _buildDismissible(child: card, item: item);
  }

  Widget _buildDismissible({required Widget child, required BaseCardDto item}) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Вправо → редактирование
          if (item is PasswordCardDto) {
            final path = AppRoutesPaths.dashboardPasswordEditWithId(item.id);
            if (GoRouter.of(context).state.matchedLocation != path) {
              context.push(path);
            }
          }
          return false;
        } else {
          // Влево → удаление
          String itemName = 'элемент';
          if (item is PasswordCardDto) {
            itemName = item.name;
          }

          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text("Удалить?"),
              content: Text("Вы уверены, что хотите удалить '$itemName'?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Отмена"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("Удалить"),
                ),
              ],
            ),
          );
          if (!mounted) return false;
          return shouldDelete ?? false;
        }
      },
      onDismissed: (_) {
        _onDelete(item.id, item.isDeleted);
      },
      child: child,
    );
  }

  Widget _buildGridCardFor(EntityType type, BaseCardDto item) {
    switch (type) {
      case EntityType.password:
        if (item is! PasswordCardDto) return const SizedBox.shrink();
        return PasswordGridCard(
          password: item,
          onToggleFavorite: () => _onToggleFavorite(item.id),
          onTogglePin: () => _onTogglePin(item.id),
          onToggleArchive: () => _onToggleArchive(item.id),
          onDelete: () => _onDelete(item.id, item.isDeleted),
          onRestore: () => _onRestore(item.id),
        );
      case EntityType.note:
        return const Card(child: Center(child: Text('Note Grid')));
      case EntityType.bankCard:
        return const Card(child: Center(child: Text('BankCard Grid')));
      case EntityType.file:
        return const Card(child: Center(child: Text('File Grid')));
      case EntityType.otp:
        return const Card(child: Center(child: Text('OTP Grid')));
    }
  }

  // --- Universal Entity Actions ---

  void _onToggleFavorite(String id) {
    ref.read(paginatedListProvider.notifier).toggleFavorite(id);
  }

  void _onTogglePin(String id) {
    ref.read(paginatedListProvider.notifier).togglePin(id);
  }

  void _onToggleArchive(String id) {
    ref.read(paginatedListProvider.notifier).toggleArchive(id);
  }

  void _onDelete(String id, bool? isDeleted) {
    if (isDeleted == true) {
      ref.read(paginatedListProvider.notifier).permanentDelete(id);
    } else {
      ref.read(paginatedListProvider.notifier).delete(id);
    }
  }

  void _onRestore(String id) {
    ref.read(paginatedListProvider.notifier).restoreFromDeleted(id);
  }
}
