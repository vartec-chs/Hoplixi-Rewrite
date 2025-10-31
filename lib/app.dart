import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/routing/router.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:tray_manager/tray_manager.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with TrayListener {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    // final appLifecycleNotifier = ref.read(appLifecycleProvider.notifier);
    // _listener = AppLifecycleListener(
    //   onDetach: () => appLifecycleNotifier.onDetach(),
    //   onHide: () => appLifecycleNotifier.onHide(),
    //   onInactive: () => appLifecycleNotifier.onInactive(),
    //   onPause: () => appLifecycleNotifier.onPause(),
    //   onRestart: () => appLifecycleNotifier.onRestart(),
    //   onResume: () => appLifecycleNotifier.onResume(),
    //   onShow: () => appLifecycleNotifier.onShow(),
    //   onExitRequested: () => appLifecycleNotifier.onExitRequested(),
    // );
  }

  @override
  void dispose() {
    _listener.dispose();
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    await WindowManager.show();
  }

  @override
  void onTrayIconLeftMouseUp() {}

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // trayManager.popUpContextMenu();
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == null) {
      logWarning('Tray menu item clicked with null key', tag: 'TrayManager');
      return;
    }
    final menuItemKey = AppTrayMenuItemKeyExtension.fromKey(menuItem.key!);
    if (menuItemKey == null) {
      logWarning(
        'Unknown tray menu item key: ${menuItem.key}',
        tag: 'TrayManager',
      );
      return;
    }
    switch (menuItemKey) {
      case AppTrayMenuItemKey.showWindow:
        await WindowManager.show();
        break;
      case AppTrayMenuItemKey.exitApp:
        await WindowManager.close();
        break;
    }
    super.onTrayMenuItemClick(menuItem);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);

    final themeMode = theme.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: MainConstants.appName,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      routerConfig: router,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
