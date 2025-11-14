import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password_cards.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/entity_list.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen> {
  late final ScrollController _scrollController;
  static const _kScrollThreshold = 200.0;
  DashboardListState<dynamic>? _cachedState;
  Timer? _loadingTimer;
  bool _showLoadingIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleListStateChange(null, ref.read(paginatedListProvider));
    });
  }

  @override
  void dispose() {
    _cancelLoadingDelay();
    _scrollController.removeListener(_onScroll);
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

  /// Универсальная защита: проверяем состояние и вызываем loadMore только когда можно
  void _tryLoadMore() {
    final asyncValue = ref.read(paginatedListProvider);
    asyncValue.when(
      data: (state) {
        if (!state.isLoadingMore && state.hasMore && !state.isLoading) {
          ref.read(paginatedListProvider.notifier).loadMore();
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _handleListStateChange(
    AsyncValue<DashboardListState<dynamic>>? previous,
    AsyncValue<DashboardListState<dynamic>> next,
  ) {
    final value = next.whenOrNull(data: (data) => data);
    if (value != null && mounted) {
      setState(() {
        _cachedState = value;
      });
    }

    if (next.hasError) {
      _cancelLoadingDelay();
      _setLoadingIndicator(false);
      return;
    }

    if (_isAwaitingData(next)) {
      _startLoadingDelay();
    } else {
      _cancelLoadingDelay();
      _setLoadingIndicator(false);
    }
  }

  bool _isAwaitingData(AsyncValue<DashboardListState<dynamic>> value) {
    if (value.isLoading) {
      return true;
    }
    final data = value.whenOrNull(data: (state) => state);
    return data?.isLoading ?? false;
  }

  void _startLoadingDelay() {
    if (_showLoadingIndicator || _loadingTimer != null) {
      return;
    }
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final asyncValue = ref.read(paginatedListProvider);
      if (_isAwaitingData(asyncValue)) {
        _setLoadingIndicator(true);
      }
      _loadingTimer = null;
    });
  }

  void _cancelLoadingDelay() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  void _setLoadingIndicator(bool value) {
    if (_showLoadingIndicator == value || !mounted) {
      return;
    }
    setState(() {
      _showLoadingIndicator = value;
    });
  }

  Widget _buildContentSliver(
    EntityType entityType,
    ViewMode viewMode,
    AsyncValue<DashboardListState<dynamic>> asyncValue,
  ) {
    final showOverlay = _showLoadingIndicator;
    return asyncValue.when(
      data: (state) => _buildStateSliver(
        entityType,
        viewMode,
        state,
        showOverlay && state.isLoading,
      ),
      error: (err, stack) => _buildErrorSliver(err),
      loading: () {
        final cached = _cachedState;
        if (cached != null) {
          return _buildStateSliver(entityType, viewMode, cached, showOverlay);
        }
        if (showOverlay) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildErrorSliver(Object err) {
    return SliverFillRemaining(
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

  Widget _buildStateSliver(
    EntityType entityType,
    ViewMode viewMode,
    DashboardListState<dynamic> state,
    bool showOverlay,
  ) {
    if (state.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entityType.icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Нет данных',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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

    final listSliver = EntitySliverList<dynamic>(
      items: state.items,
      viewMode: viewMode,
      listBuilder: (ctx, item) => _buildListCardFor(entityType, item),
      gridBuilder: (ctx, item) => _buildGridCardFor(entityType, item),
    );

    final footer = state.isLoadingMore
        ? const SliverToBoxAdapter(
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
          )
        : state.hasMore
        ? const SliverToBoxAdapter(child: SizedBox(height: 8))
        : const SliverToBoxAdapter(
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

    if (showOverlay) {
      return SliverStack(
        children: [
          listSliver,
          const SliverFillRemaining(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black38),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    return MultiSliver(children: [listSliver, footer]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<DashboardListState<dynamic>>>(
      paginatedListProvider,
      _handleListStateChange,
    );
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

  /// Билдер для карточки в режиме списка
  Widget _buildListCardFor(EntityType type, dynamic item) {
    switch (type) {
      case EntityType.password:
        return PasswordListCard(
          password: item as PasswordCardDto,
          onToggleFavorite: () => _onPasswordToggleFavorite(item),
          onTogglePin: () => _onPasswordTogglePin(item),
          onToggleArchive: () => _onPasswordToggleArchive(item),
          onDelete: () => _onPasswordDelete(item),
          onRestore: () => _onPasswordRestore(item),
        );
      case EntityType.note:
        return const Center(child: Text('Note card TODO'));
      case EntityType.bankCard:
        return const Center(child: Text('BankCard card TODO'));
      case EntityType.file:
        return const Center(child: Text('File card TODO'));
      case EntityType.otp:
        return const Center(child: Text('OTP card TODO'));
    }
  }

  /// Билдер для карточки в режиме сетки
  Widget _buildGridCardFor(EntityType type, dynamic item) {
    switch (type) {
      case EntityType.password:
        return PasswordGridCard(
          password: item as PasswordCardDto,
          onToggleFavorite: () => _onPasswordToggleFavorite(item),
          onTogglePin: () => _onPasswordTogglePin(item),
          onToggleArchive: () => _onPasswordToggleArchive(item),
          onDelete: () => _onPasswordDelete(item),
          onRestore: () => _onPasswordRestore(item),
        );
      case EntityType.note:
        return const Center(child: Text('Note grid TODO'));
      case EntityType.bankCard:
        return const Center(child: Text('BankCard grid TODO'));
      case EntityType.file:
        return const Center(child: Text('File grid TODO'));
      case EntityType.otp:
        return const Center(child: Text('OTP grid TODO'));
    }
  }

  void _onPasswordToggleFavorite(PasswordCardDto password) {
    ref.read(paginatedListProvider.notifier).toggleFavorite(password.id);
  }

  void _onPasswordTogglePin(PasswordCardDto password) {
    ref.read(paginatedListProvider.notifier).togglePin(password.id);
  }

  void _onPasswordToggleArchive(PasswordCardDto password) {
    ref.read(paginatedListProvider.notifier).toggleArchive(password.id);
  }

  void _onPasswordDelete(PasswordCardDto password) {
    if (password.isDeleted) {
      // Если запись уже удалена, выполняем окончательное удаление
      ref.read(paginatedListProvider.notifier).permanentDelete(password.id);
    } else {
      // Иначе выполняем мягкое удаление
      ref.read(paginatedListProvider.notifier).delete(password.id);
    }
  }

  void _onPasswordRestore(PasswordCardDto password) {
    ref.read(paginatedListProvider.notifier).restoreFromDeleted(password.id);
  }
}
