import 'package:flutter/widgets.dart';

import 'app_logger.dart';

class LoggingRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logInfo(
      '[ROUTE] ➕ PUSH to ${route.settings.name ?? route.settings.arguments}',
      tag: 'Route',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logInfo(
      '[ROUTE] ⬅️ POP from ${route.settings.name ?? route.settings.arguments}',
      tag: 'Route',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logInfo(
      '[ROUTE] 🔁 REPLACE ${oldRoute?.settings.name} → ${newRoute?.settings.name}',
      tag: 'Route',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    logInfo('[ROUTE] ❌ REMOVE ${route.settings.name}', tag: 'Route');
  }


}
