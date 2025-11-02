import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/routing/paths.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

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
    if (location.startsWith(AppRoutesPaths.dashboardCategories)) return 1;
    if (location.startsWith(AppRoutesPaths.dashboardSearch)) return 2;
    if (location.startsWith(AppRoutesPaths.dashboardSettings)) return 3;
    return 0; // home
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutesPaths.dashboard);
        break;
      case 1:
        context.go(AppRoutesPaths.dashboardCategories);
        break;
      case 2:
        context.go(AppRoutesPaths.dashboardSearch);
        break;
      case 3:
        context.go(AppRoutesPaths.dashboardSettings);
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
            body: Row(
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
          );
        } else {
          // Mobile layout: BottomNavigationBar (без анимации для избежания конфликтов GlobalKey)
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              selectedIndex,
            ),
            floatingActionButton: selectedIndex == 0
                ? FloatingActionButton(
                    onPressed: () {
                      // Добавить создание записи
                    },
                    child: const Icon(Icons.add),
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
          child: FloatingActionButton(
            elevation: 0,
            onPressed: () {
              // Добавить создание записи
            },
            child: const Icon(Icons.add),
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
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: Text('Поиск'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Настройки'),
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
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Поиск',
            index: 2,
            selectedIndex: selectedIndex,
          ),
          _buildBottomNavIconButton(
            context,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Настройки',
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

/// Smooth notch that visually matches a rounded-rect "guest".
///
/// This implementation is an adaptation of Flutter's CircularNotchedRectangle
/// approach, but uses an effective radius computed from the guest RRect,
/// and keeps host/guest corner radii into account. It produces a smooth
/// bezier+arc notch that looks natural for FAB-like guests and for
/// moderately rounded rectangles.
///
/// Note: this is an approximation — for extreme aspect ratios or very large
/// guest corner radii, the notch will still be smooth but will not strictly
/// follow the exact RRect contour on every corner.
class SmoothRoundedNotchedRectangle extends NotchedShape {
  const SmoothRoundedNotchedRectangle({
    this.inverted = false,
    this.hostRadius = Radius.zero,
    this.guestCorner = Radius.zero,
    this.notchMargin = 0.0,
    // Fine-tune the "tightness" of the bezier transitions:
    this.s1 = 15.0,
    this.s2 = 1.0,
  });

  final bool inverted;
  final Radius hostRadius;
  final Radius guestCorner;
  final double notchMargin;
  final double s1;
  final double s2;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    final RRect hostRRect = RRect.fromRectAndRadius(host, hostRadius);
    final Path hostPath = Path()..addRRect(hostRRect);

    if (guest == null || !host.overlaps(guest)) {
      return hostPath;
    }

    final Rect inflatedGuest = guest.inflate(notchMargin);
    final double r = math.min(inflatedGuest.width, inflatedGuest.height) / 2.0;
    final Radius notchRadius = Radius.circular(r);

    final double invertMultiplier = inverted ? -1.0 : 1.0;
    final double a = -r - s2;
    final double b =
        (inverted ? host.bottom : host.top) - inflatedGuest.center.dy;

    if (b == 0.0) {
      final Path guestPath = Path()
        ..addRRect(RRect.fromRectAndRadius(inflatedGuest, guestCorner));
      return Path.combine(PathOperation.difference, hostPath, guestPath);
    }

    final double underSqrt = b * b * r * r * (a * a + b * b - r * r);
    final double n2 = underSqrt <= 0.0 ? 0.0 : math.sqrt(underSqrt);
    final double denom = (a * a + b * b);
    if (denom == 0.0) {
      final Path guestPath = Path()
        ..addRRect(RRect.fromRectAndRadius(inflatedGuest, guestCorner));
      return Path.combine(PathOperation.difference, hostPath, guestPath);
    }

    final double p2xA = ((a * r * r) - n2) / denom;
    final double p2xB = ((a * r * r) + n2) / denom;
    final double p2yA =
        math.sqrt(math.max(0.0, r * r - p2xA * p2xA)) * invertMultiplier;
    final double p2yB =
        math.sqrt(math.max(0.0, r * r - p2xB * p2xB)) * invertMultiplier;

    final List<Offset> p = List<Offset>.filled(6, Offset.zero);
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = (cmp * p2yA > cmp * p2yB) ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);
    p[3] = Offset(-p[2].dx, p[2].dy);
    p[4] = Offset(-p[1].dx, p[1].dy);
    p[5] = Offset(-p[0].dx, p[0].dy);

    for (int i = 0; i < p.length; i++) {
      p[i] += inflatedGuest.center;
    }

    // --- FIX: start/end top edge at the tangency points of top corner arcs ---
    // Получаем горизонтальные радиусы верхних углов у hostRRect:
    final double leftTopRadiusX = hostRRect.tlRadiusX;
    final double rightTopRadiusX = hostRRect.trRadiusX;

    // Точки, откуда действительно начинают и заканчивают прямую часть верхнего ребра:
    final double startX = host.left + leftTopRadiusX;
    final double endX = host.right - rightTopRadiusX;

    final Path path = Path()..moveTo(startX, host.top);

    if (!inverted) {
      path
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(p[3], radius: notchRadius, clockwise: false)
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        // go back to the straight top edge but stop before the top-right corner arc
        ..lineTo(endX, host.top)
        // now go down along the rounded corner area — intersection with hostPath will clip precise arc
        ..lineTo(host.right, host.top + hostRRect.trRadiusY)
        ..lineTo(host.right, host.bottom)
        ..lineTo(host.left, host.bottom);
    } else {
      // inverted: notch on bottom — keep original logic but also avoid drawing into top-left arc:
      path
        ..lineTo(host.right, host.top)
        ..lineTo(host.right, host.bottom)
        ..lineTo(p[5].dx, p[5].dy)
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[3].dx, p[3].dy)
        ..arcToPoint(p[2], radius: notchRadius, clockwise: false)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[0].dx, p[0].dy)
        ..lineTo(host.left, host.bottom);
    }

    // Intersect with hostRRect so only the host's rounded corners remain and
    // any tiny overlaps are clipped away.
    final Path combined = Path.combine(
      PathOperation.intersect,
      path..close(),
      hostPath,
    );

    return combined;
  }
}
