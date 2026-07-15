import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/localization/translations.dart';

class TrayService with TrayListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  bool _isInit = false;
  String? _lastLocale;
  bool? _lastIsDark;

  Future<void> init() async {
    if (_isInit || !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    _isInit = true;

    trayManager.addListener(this);

    // Initial icon, will be updated by theme listener
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray_icon_light.ico' : 'assets/app_icon.png',
    );
    await trayManager.setToolTip('Zenist');
  }

  Future<void> updateMenu(String locale) async {
    if (!_isInit) return;
    if (_lastLocale == locale) return;
    _lastLocale = locale;

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_app',
          label: Translations.tr('tray_show', locale),
        ),
        MenuItem(
          key: 'hide_app',
          label: Translations.tr('tray_hide', locale),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: Translations.tr('tray_exit', locale),
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> updateIcon(bool isDark) async {
    if (!_isInit) return;
    if (_lastIsDark == isDark) return;
    _lastIsDark = isDark;
    
    final iconPath = Platform.isWindows
        ? (isDark ? 'assets/tray_icon_dark.ico' : 'assets/tray_icon_light.ico')
        : 'assets/app_icon.png';
    await trayManager.setIcon(iconPath);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_app':
        windowManager.show();
        windowManager.focus();
        break;
      case 'hide_app':
        windowManager.hide();
        break;
      case 'exit_app':
        // Exit the app gracefully
        windowManager.destroy();
        exit(0);
    }
  }

  void dispose() {
    if (_isInit) {
      trayManager.removeListener(this);
      trayManager.destroy();
    }
  }
}
