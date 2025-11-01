import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router_refresh_provider.dart';
import 'package:hoplixi/routing/routes.dart';
import 'package:hoplixi/shared/ui/desktop_shell.dart';
import 'package:universal_platform/universal_platform.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the RouterRefreshNotifier to trigger refreshes
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider.notifier);

  final router = GoRouter(
    initialLocation: AppRoutesPaths.home,
    navigatorKey: navigatorKey,
    observers: [LoggingRouteObserver()],
    refreshListenable: refreshNotifier,
    routes: UniversalPlatform.isDesktop
        ? [
            ShellRoute(
              builder: (context, state, child) => DesktopShell(child: child),
              routes: appRoutes,
            ),
          ]
        : appRoutes,
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
