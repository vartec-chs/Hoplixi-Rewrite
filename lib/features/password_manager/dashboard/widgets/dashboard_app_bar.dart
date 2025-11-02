import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Полноценный SliverAppBar для дашборда с поиском и вкладками
class DashboardSliverAppBar extends StatefulWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Высота расширенного состояния
  final double expandedHeight;

  /// Высота свернутого состояния
  final double collapsedHeight;

  /// Должен ли AppBar быть закрепленным при прокрутке
  final bool pinned;

  /// Должен ли AppBar плавать при прокрутке
  final bool floating;

  /// Должен ли AppBar быстро появляться при прокрутке вверх
  final bool snap;

  /// Дополнительные actions в AppBar
  final List<Widget>? additionalActions;

  /// Заголовок AppBar
  final String title;

  const DashboardSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.expandedHeight = 160.0,
    this.collapsedHeight = 60.0,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.additionalActions,
    this.title = 'Dashboard',
  });

  @override
  State<DashboardSliverAppBar> createState() => _DashboardSliverAppBarState();
}

class _DashboardSliverAppBarState extends State<DashboardSliverAppBar>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  // Список тестовых вкладок
  final List<String> _tabs = ['Все', 'Избранное', 'Недавние', 'Архив'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Обработка поиска
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      collapsedHeight: widget.collapsedHeight,
      pinned: widget.pinned,
      floating: widget.floating,
      snap: widget.snap,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,

      // Кнопка открытия drawer слева
      leading: widget.onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
              tooltip: 'Открыть меню',
            )
          : null,

      // Actions справа
      actions: [
        // Кнопка фильтров
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Открыть фильтры
          },
          tooltip: 'Фильтры',
        ),

        // Дополнительные actions
        if (widget.additionalActions != null) ...widget.additionalActions!,

        const SizedBox(width: 8),
      ],

      // Заголовок в свернутом состоянии
      title: Text(
        widget.title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Расширенный контент
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Нижняя часть с поиском и вкладками
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        // Поле поиска
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            decoration:
                                primaryInputDecoration(
                                  context,
                                  hintText: 'Поиск...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,

                                  filled: true,
                                ).copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                          ),
                        ),

                        // Вкладки фильтров
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: List.generate(_tabs.length, (index) {
                              final isSelected = _selectedTabIndex == index;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTabIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _tabs[index],
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
      ),
    );
  }
}

/// Компактная версия DashboardSliverAppBar для использования в различных экранах
class CompactDashboardSliverAppBar extends StatelessWidget {
  /// Callback для открытия drawer
  final VoidCallback? onMenuPressed;

  /// Заголовок
  final String title;

  /// Дополнительные actions
  final List<Widget>? actions;

  /// Показывать ли кнопку фильтров
  final bool showFilterButton;

  /// Callback при открытии фильтров
  final VoidCallback? onFilterPressed;

  const CompactDashboardSliverAppBar({
    super.key,
    this.onMenuPressed,
    this.title = 'Hoplixi',
    this.actions,
    this.showFilterButton = false,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,

      leading: onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
              tooltip: 'Открыть меню',
            )
          : null,

      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      actions: [
        if (showFilterButton) ...[
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onFilterPressed,
            tooltip: 'Фильтры',
          ),
        ],
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}
