import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router_refresh_provider.dart';
import 'package:hoplixi/routing/routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the RouterRefreshNotifier to trigger refreshes
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider.notifier);

  final router = GoRouter(
    initialLocation: AppRoutesPaths.splash,
    navigatorKey: navigatorKey,
    refreshListenable: refreshNotifier,
    routes: [
      // Define your app routes here
      ...appRoutes,
    ],
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
