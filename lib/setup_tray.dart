import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

Future<void> setupTray() async {
  await trayManager.setIcon(
    Platform.isWindows ? 'assets/logo/logo.ico' : 'assets/logo/logo.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Показать окно'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Выход из приложения'),
    ],
  );
  await trayManager.setContextMenu(menu);
  await trayManager.setToolTip('Hoplixi');
  // await trayManager.setTitle('Hoplixi');
}

enum AppTrayMenuItemKey {
  showWindow('show_window'),
  exitApp('exit_app');

  final String key;
  const AppTrayMenuItemKey(this.key);
}

extension AppTrayMenuItemKeyExtension on AppTrayMenuItemKey {
  static AppTrayMenuItemKey? fromKey(String key) {
    for (var item in AppTrayMenuItemKey.values) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }
}
