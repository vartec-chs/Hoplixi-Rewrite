import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
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
            // AppBar с поиском, фильтрами и вкладками
            DashboardSliverAppBar(
              expandedHeight: 178.0,
              collapsedHeight: 60.0,
              pinned: true,
              floating: false,
              snap: false,
              showEntityTypeSelector: true,
            ),

            // Тулбар со списком
            SliverToBoxAdapter(child: _buildToolbar(entityType, viewMode)),

            // Контент списка
            asyncValue.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
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
              ),
              data: (state) {
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final listSliver = EntitySliverList<dynamic>(
                  items: state.items,
                  viewMode: viewMode,
                  listBuilder: (ctx, item) =>
                      _buildListCardFor(entityType, item),
                  gridBuilder: (ctx, item) =>
                      _buildGridCardFor(entityType, item),
                );

                // Footer для индикации загрузки или конца списка
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

                // Если initial loading — показываем overlay
                if (state.isLoading) {
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

                // Обычная ситуация: список + footer
                return MultiSliver(children: [listSliver, footer]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Билдер для карточки в режиме списка
  Widget _buildListCardFor(EntityType type, dynamic item) {
    switch (type) {
      case EntityType.password:
        return _PasswordListCard(
          password: item as PasswordCardDto,
          onTap: () => _onPasswordTap(item),
          onEdit: () => _onPasswordEdit(item),
          onCopyPassword: () => _onPasswordCopy(item),
          onToggleFavorite: () => _onPasswordToggleFavorite(item),
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
        return _PasswordGridCard(
          password: item as PasswordCardDto,
          onTap: () => _onPasswordTap(item),
          onEdit: () => _onPasswordEdit(item),
          onCopyPassword: () => _onPasswordCopy(item),
          onToggleFavorite: () => _onPasswordToggleFavorite(item),
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

  /// Callbacks для работы с паролями
  void _onPasswordTap(PasswordCardDto password) {
    // TODO: открыть детальный просмотр
    debugPrint('Open password: ${password.name}');
  }

  void _onPasswordEdit(PasswordCardDto password) {
    // TODO: открыть форму редактирования
    debugPrint('Edit password: ${password.name}');
  }

  void _onPasswordCopy(PasswordCardDto password) {
    // TODO: скопировать пароль в буфер обмена
    debugPrint('Copy password: ${password.name}');
  }

  void _onPasswordToggleFavorite(PasswordCardDto password) {
    ref.read(paginatedListProvider.notifier).toggleFavorite(password.id);
  }

  /// Тулбар с переключателем режима отображения
  Widget _buildToolbar(EntityType entityType, ViewMode viewMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entityType.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ToggleButtons(
            isSelected: [viewMode == ViewMode.list, viewMode == ViewMode.grid],
            onPressed: (i) {
              ref
                  .read(currentViewModeProvider.notifier)
                  .setViewMode(i == 0 ? ViewMode.list : ViewMode.grid);
            },
            children: const [Icon(Icons.view_list), Icon(Icons.grid_view)],
          ),
        ],
      ),
    );
  }
}

// ---------- Тестовые карточки для паролей ----------

/// Карточка пароля для режима списка
class _PasswordListCard extends StatelessWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCopyPassword;
  final VoidCallback? onToggleFavorite;

  const _PasswordListCard({
    required this.password,
    this.onTap,
    this.onEdit,
    this.onCopyPassword,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (password.login != null || password.email != null)
                      Text(
                        password.login ?? password.email ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (password.categoryName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              password.categoryName!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.blue, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (password.usedCount > 0)
                          Text(
                            'Использован: ${password.usedCount} раз',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Действия
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (password.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      password.isFavorite ? Icons.star : Icons.star_border,
                      color: password.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: 'Избранное',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: onCopyPassword,
                    tooltip: 'Скопировать пароль',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Редактировать',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка пароля для режима сетки
class _PasswordGridCard extends StatelessWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCopyPassword;
  final VoidCallback? onToggleFavorite;

  const _PasswordGridCard({
    required this.password,
    this.onTap,
    this.onEdit,
    this.onCopyPassword,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой и действиями
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  if (password.isPinned)
                    const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                  IconButton(
                    icon: Icon(
                      password.isFavorite ? Icons.star : Icons.star_border,
                      color: password.isFavorite ? Colors.amber : null,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Название
              Text(
                password.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Логин/email
              if (password.login != null || password.email != null)
                Text(
                  password.login ?? password.email ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              // Категория
              if (password.categoryName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    password.categoryName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              // Действия
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onCopyPassword,
                    tooltip: 'Скопировать',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                    tooltip: 'Редактировать',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
