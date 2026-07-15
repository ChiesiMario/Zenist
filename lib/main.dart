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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  final sharedPreferences = await SharedPreferences.getInstance();

  WindowOptions windowOptions = const WindowOptions(
    title: 'Zenist',
    titleBarStyle: TitleBarStyle.hidden,
  );
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
    await windowManager.show();
    await windowManager.focus();
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
    Future.microtask(() {
      ref.read(autoSyncManagerProvider);
    });
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

    bool isDark = appThemeMode == ThemeMode.dark || 
        (appThemeMode == ThemeMode.system && PlatformDispatcher.instance.platformBrightness == Brightness.dark);

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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32.0), // kWindowCaptionHeight is usually 32
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
        );
      },
      home: const TodoListPage(),
    );
  }
}
