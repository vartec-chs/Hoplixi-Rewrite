import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/routing/paths.dart';

final List<GoRoute> appRoutes = [
  GoRoute(
    path: AppRoutesPaths.splash,
    builder: (context, state) => const BaseScreen(title: 'Splash Screen'),
  ),
  GoRoute(
    path: AppRoutesPaths.home,
    builder: (context, state) => const BaseScreen(title: 'Home'),
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
