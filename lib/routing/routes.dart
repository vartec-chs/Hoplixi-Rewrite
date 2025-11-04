import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/category_manager/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/categories_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/search_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_settings_screen.dart';
import 'package:hoplixi/features/password_manager/icon_manager/icon_manager_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/features/component_showcase/component_showcase_screen.dart';
import 'package:hoplixi/routing/paths.dart';

/// Флаг для отключения/включения кастомных анимаций при переходах между экранами dashboard
/// true = кастомные Scale+Fade анимации, false = стандартные MaterialPage анимации
const bool _enableDashboardTransitions = false;

final List<RouteBase> appRoutes = [
  GoRoute(
    path: AppRoutesPaths.splash,
    builder: (context, state) => const BaseScreen(title: 'Splash Screen'),
  ),
  GoRoute(
    path: AppRoutesPaths.home,
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.logs,
    builder: (context, state) => const LogsTabsScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.componentShowcase,
    builder: (context, state) => const ComponentShowcaseScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.createStore,
    builder: (context, state) => const CreateStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.openStore,
    builder: (context, state) => const OpenStoreScreen(),
  ),

  // Dashboard с вложенными роутами через ShellRoute
  ShellRoute(
    builder: (context, state, child) => DashboardLayout(child: child),
    routes: [
      GoRoute(
        path: AppRoutesPaths.dashboardHome,
        pageBuilder: (context, state) {
          if (!_enableDashboardTransitions) {
            return MaterialPage(
              key: state.pageKey,
              child: const DashboardHomeScreen(),
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardHomeScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 150),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardCategories,
        pageBuilder: (context, state) {
          if (!_enableDashboardTransitions) {
            return MaterialPage(
              key: state.pageKey,
              child: const CategoriesScreen(),
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CategoriesScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  if (secondaryAnimation.status == AnimationStatus.forward ||
                      secondaryAnimation.status == AnimationStatus.reverse) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.9).animate(
                        CurvedAnimation(
                          parent: secondaryAnimation,
                          curve: Curves.easeInCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: 1.0,
                          end: 0.0,
                        ).animate(secondaryAnimation),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  }
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardSearch,
        pageBuilder: (context, state) {
          if (!_enableDashboardTransitions) {
            return MaterialPage(
              key: state.pageKey,
              child: const SearchScreen(),
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SearchScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  if (secondaryAnimation.status == AnimationStatus.forward ||
                      secondaryAnimation.status == AnimationStatus.reverse) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.9).animate(
                        CurvedAnimation(
                          parent: secondaryAnimation,
                          curve: Curves.easeInCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: 1.0,
                          end: 0.0,
                        ).animate(secondaryAnimation),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  }
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutesPaths.dashboardSettings,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const DashboardSettingsScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardIconManager,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const IconManagerScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutesPaths.dashboardCategoryManager,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const CategoryManagerScreen(),
          );
        },
      ),
    ],
  ),
];

class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title ?? 'Base Screen')));
  }
}
