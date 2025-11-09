import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';
import 'smooth_rounded_notched_rectangle.dart';

/// Адаптивный layout для dashboard с использованием ShellRoute
/// На больших экранах: NavigationRail слева + main content + sidebar справа (child)
/// На маленьких экранах: BottomNavigationBar + main content, sidebar открывается по отдельным роутам
class DashboardLayout extends StatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  int _previousIndex = 0;
  bool _fabIsOpen = false;
  final GlobalKey<ExpandableFABState> _fabKey = GlobalKey();
  final GlobalKey<ExpandableFABState> _mobileFabKey = GlobalKey();
  bool _mobileFabIsOpen = false;

  // FAB параметры
  String _entityName = 'Пароль';

  // FAB действия
  void _onCreateEntity() {}
  void _onCreateCategory() {}
  void _onCreateTag() {}
  void _onIconCreate() {}

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutesPaths.dashboardCategoryManager)) return 1;
    if (location.startsWith(AppRoutesPaths.dashboardIconManager)) return 2;
    if (location.startsWith(AppRoutesPaths.dashboardTagManager)) return 3;
    return 0; // home
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutesPaths.dashboard);
        break;
      case 1:
        context.go(AppRoutesPaths.dashboardCategoryManager);
        break;
      case 2:
        context.go(AppRoutesPaths.dashboardIconManager);
        break;
      case 3:
        context.go(AppRoutesPaths.dashboardTagManager);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final selectedIndex = _getSelectedIndex(context);

        // Управление анимацией при изменении выбранного индекса
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_previousIndex != selectedIndex) {
            if (selectedIndex == 0) {
              // Закрываем sidebar
              _animationController.reverse();
            } else if (_previousIndex == 0) {
              // Открываем sidebar
              _animationController.forward();
            }
            _previousIndex = selectedIndex;
          }
        });

        if (isDesktop) {
          // Desktop layout: NavigationRail + Content (или Content + Sidebar)
          return Scaffold(
            body: Stack(
              children: [
                Row(
                  children: [
                    // NavigationRail слева
                    _buildNavigationRail(context, selectedIndex),

                    // Home контент (всегда присутствует)
                    const Expanded(flex: 1, child: DashboardHomeScreen()),

                    // Анимированный Sidebar справа
                    AnimatedBuilder(
                      animation: _sidebarAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _sidebarAnimation.value,
                            child: SizedBox(
                              width: constraints.maxWidth / 2.15,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                                  border: Border(
                                    left: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: selectedIndex != 0
                                    ? widget.child
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Overlay для раскрывающихся кнопок FAB
                if (_fabKey.currentState != null)
                  FABActionsOverlay(
                    isOpen: _fabIsOpen,
                    animation: _fabKey.currentState!.expandAnimation,
                    actions: _fabKey.currentState!.actionButtons,
                    direction: FABExpandDirection.right,
                    spacing: 60,
                    fabOffset: const Offset(16, 16),
                    onBackdropTap: () {
                      // Закрываем FAB при клике на затемнение
                      _fabKey.currentState?.toggle();
                    },
                    onCloseTap: () {
                      // Закрываем FAB при клике на кнопку закрытия
                      _fabKey.currentState?.toggle();
                    },
                  ),
              ],
            ),
          );
        } else {
          // Mobile layout: BottomNavigationBar (без анимации для избежания конфликтов GlobalKey)
          return Scaffold(
            body: Stack(
              children: [
                widget.child,
                // Overlay для раскрывающихся кнопок FAB на мобильном
                if (_mobileFabKey.currentState != null)
                  FABActionsOverlay(
                    isOpen: _mobileFabIsOpen,
                    animation: _mobileFabKey.currentState!.expandAnimation,
                    actions: _mobileFabKey.currentState!.actionButtons,
                    direction: FABExpandDirection.up,
                    spacing: 60,
                    fabOffset: Offset(
                      MediaQuery.of(context).size.width / 2 - 28,
                      MediaQuery.of(context).size.height - 126,
                    ),
                    showCloseButton:
                        false, // Не показываем доп кнопку на мобильном
                    onBackdropTap: () {
                      _mobileFabKey.currentState?.toggle();
                    },
                  ),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              selectedIndex,
            ),
            floatingActionButton: selectedIndex == 0
                ? ExpandableFAB(
                    key: _mobileFabKey,
                    expandDirection: FABExpandDirection.up,
                    showActionsInOverlay: true,
                    onStateChanged: (isOpen) {
                      setState(() {
                        _mobileFabIsOpen = isOpen;
                      });
                    },
                    onCreateEntity: _onCreateEntity,
                    entityName: _entityName,
                    onCreateCategory: _onCreateCategory,
                    onCreateTag: _onCreateTag,
                    onIconCreate: _onIconCreate,
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        }
      },
    );
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpandableFAB(
            key: _fabKey,
            expandDirection: FABExpandDirection.right,
            showActionsInOverlay: true,
            onStateChanged: (isOpen) {
              setState(() {
                _fabIsOpen = isOpen;
              });
            },
            onCreateEntity: _onCreateEntity,
            entityName: _entityName,
            onCreateCategory: _onCreateCategory,
            onCreateTag: _onCreateTag,
            onIconCreate: _onIconCreate,
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Главная'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('Категории'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.import_contacts),
            selectedIcon: Icon(Icons.import_contacts_outlined),
            label: Text('Иконки'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.tag_outlined),
            selectedIcon: Icon(Icons.tag),
            label: Text('Теги'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int selectedIndex) {
    return BottomAppBar(
      shape: const SmoothRoundedNotchedRectangle(
        // hostRadius: Radius.circular(8),
        guestCorner: Radius.circular(20),
        notchMargin: 4.0,
        s1: 18.0,
        s2: 18.0,
      ),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 70,
      // notchMargin: 2,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildBottomNavIconButton(
            context,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Главная',
            index: 0,
            selectedIndex: selectedIndex,
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            label: 'Категории',
            index: 1,
            selectedIndex: selectedIndex,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: selectedIndex == 0 ? 40 : 0,
            child: const SizedBox(width: 40),
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.import_contacts_outlined,
            selectedIcon: Icons.import_contacts,
            label: 'Иконки',
            index: 2,
            selectedIndex: selectedIndex,
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.tag_outlined,
            selectedIcon: Icons.tag,
            label: 'Теги',
            index: 3,
            selectedIndex: selectedIndex,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIconButton(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _onDestinationSelected(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
