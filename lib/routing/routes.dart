import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_screen.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store_screen.dart';
import 'package:hoplixi/features/home/home_screen.dart';
import 'package:hoplixi/features/logs_viewer/screens/logs_tabs_screen.dart';
import 'package:hoplixi/routing/paths.dart';

final List<GoRoute> appRoutes = [
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
    path: AppRoutesPaths.createStore,
    builder: (context, state) => const CreateStoreScreen(),
  ),
  GoRoute(
    path: AppRoutesPaths.openStore,
    builder: (context, state) => const OpenStoreScreen(),
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
