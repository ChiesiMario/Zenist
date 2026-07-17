import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'presentation/pages/todo_list_page.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:window_manager/window_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/providers/settings_provider.dart';
import 'application/services/auto_sync_manager.dart';
import 'presentation/widgets/custom_title_bar.dart';
import 'application/services/tray_service.dart';
import 'application/services/startup_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await TrayService.instance.init();

  final sharedPreferences = await SharedPreferences.getInstance();

  WindowOptions windowOptions = const WindowOptions(
    title: 'Zenist',
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  await windowManager.setPreventClose(true);

  bool isMinimized = args.contains('--minimized');

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    final double? x = sharedPreferences.getDouble('window_x');
    final double? y = sharedPreferences.getDouble('window_y');
    final double? width = sharedPreferences.getDouble('window_width');
    final double? height = sharedPreferences.getDouble('window_height');

    if (x != null && y != null && width != null && height != null) {
      await windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
    } else {
      await windowManager.setSize(const Size(750, 750));
      await windowManager.center();
    }
    
    if (!isMinimized) {
      await windowManager.show();
      await windowManager.focus();
    }
  });

  runApp(
    // ProviderScope 讓 Riverpod 能夠管理全域狀態
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ZenistApp(),
    ),
  );
}

class _CustomScrollBehavior extends MaterialScrollBehavior {
  const _CustomScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return RawScrollbar(
      controller: details.controller,
      thickness: 4.0,
      radius: const Radius.circular(4.0),
      crossAxisMargin: 3.0,
      thumbColor: ShadTheme.of(context).colorScheme.border,
      child: child,
    );
  }
}

class ZenistApp extends ConsumerStatefulWidget {
  const ZenistApp({super.key});

  @override
  ConsumerState<ZenistApp> createState() => _ZenistAppState();
}

class _ZenistAppState extends ConsumerState<ZenistApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // 初始化 AutoSyncManager，讓其接管啟動、週期與喚醒同步
    Future.microtask(() async {
      ref.read(autoSyncManagerProvider);
      
      final settings = ref.read(settingsProvider);
      if (settings.launchAtStartup) {
        await StartupService.enable();
      } else {
        await StartupService.disable();
      }
    });

    TrayService.instance.onToggleStartup = (bool value) async {
      await ref.read(settingsProvider.notifier).updateLaunchAtStartup(value);
      if (value) {
        await StartupService.enable();
      } else {
        await StartupService.disable();
      }
    };
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _saveWindowBounds() async {
    final bounds = await windowManager.getBounds();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('window_x', bounds.left);
    await prefs.setDouble('window_y', bounds.top);
    await prefs.setDouble('window_width', bounds.width);
    await prefs.setDouble('window_height', bounds.height);
  }

  @override
  void onWindowClose() {
    final settings = ref.read(settingsProvider);
    if (settings.closeToTray) {
      windowManager.hide();
    } else {
      windowManager.destroy();
    }
  }

  @override
  void onWindowMoved() {
    _saveWindowBounds();
  }

  @override
  void onWindowResized() {
    _saveWindowBounds();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    ThemeMode appThemeMode;
    switch (settings.themeMode) {
      case 'light':
        appThemeMode = ThemeMode.light;
        break;
      case 'dark':
        appThemeMode = ThemeMode.dark;
        break;
      default:
        appThemeMode = ThemeMode.system;
    }

    bool isDark =
        appThemeMode == ThemeMode.dark ||
        (appThemeMode == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);

    // 更新系統托盤圖示與語言
    TrayService.instance.updateIcon(isDark);
    TrayService.instance.updateMenu(settings.locale, settings.launchAtStartup);

    return ShadApp(
      title: 'Zenist',
      debugShowCheckedModeBanner: false,
      themeMode: appThemeMode,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(
          background: Color(0xFFFAFAFA), // 極淡灰背景，突顯卡片
        ),
        textTheme: ShadTextTheme(family: settings.fontFamily),
        radius: BorderRadius.circular(12),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        textTheme: ShadTextTheme(family: settings.fontFamily),
        radius: BorderRadius.circular(12),
      ),
      builder: (context, child) {
        final scaffoldChild = ScaffoldMessenger(child: child!);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ScrollConfiguration(
            behavior: const _CustomScrollBehavior(),
            child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 32.0,
                ), // kWindowCaptionHeight is usually 32
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.escape): () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  },
                  child: Focus(
                    autofocus: true,
                    canRequestFocus: false,
                    descendantsAreFocusable: true,
                    child: scaffoldChild,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 32.0,
                child: Material(
                  type: MaterialType.transparency,
                  child: CustomTitleBar(isDark: isDark),
                ),
              ),
            ],
          ),
          ),
        );
      },
      home: const TodoListPage(),
    );
  }
}
