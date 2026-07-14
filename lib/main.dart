import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'presentation/pages/todo_list_page.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/providers/settings_provider.dart';
import 'application/services/sync_service.dart';
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
    
    // 背景觸發雲端同步
    Future.microtask(() async {
      try {
        final syncService = ref.read(syncServiceProvider);
        await syncService.syncWithDropbox();
      } catch (e) {
        debugPrint('App Launch Sync failed: $e');
      }
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

    return ShadApp(
      title: 'Zenist',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        colorScheme: const ShadZincColorScheme.light(
          background: Color(0xFFFAFAFA), // 極淡灰背景，突顯卡片
        ),
        textTheme: ShadTextTheme.fromGoogleFont(
          ({textStyle, color, backgroundColor, fontSize, fontWeight, fontStyle, letterSpacing, wordSpacing, textBaseline, height, locale, foreground, background, shadows, fontFeatures, decoration, decorationColor, decorationStyle, decorationThickness}) {
            final baseStyle = textStyle ?? const TextStyle();
            return baseStyle.copyWith(
              fontFamily: settings.fontFamily,
              fontFamilyFallback: ['NotoSansSC'],
              color: color ?? baseStyle.color,
              backgroundColor: backgroundColor ?? baseStyle.backgroundColor,
              fontSize: fontSize ?? baseStyle.fontSize,
              fontWeight: fontWeight ?? baseStyle.fontWeight,
              fontStyle: fontStyle ?? baseStyle.fontStyle,
              letterSpacing: letterSpacing ?? baseStyle.letterSpacing,
              wordSpacing: wordSpacing ?? baseStyle.wordSpacing,
              textBaseline: textBaseline ?? baseStyle.textBaseline,
              height: height ?? baseStyle.height,
              locale: locale ?? baseStyle.locale,
              foreground: foreground ?? baseStyle.foreground,
              background: background ?? baseStyle.background,
              shadows: shadows ?? baseStyle.shadows,
              fontFeatures: fontFeatures ?? baseStyle.fontFeatures,
              decoration: decoration ?? baseStyle.decoration,
              decorationColor: decorationColor ?? baseStyle.decorationColor,
              decorationStyle: decorationStyle ?? baseStyle.decorationStyle,
              decorationThickness: decorationThickness ?? baseStyle.decorationThickness,
            );
          },
        ),
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
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 32.0,
                child: Material(
                  type: MaterialType.transparency,
                  child: CustomTitleBar(),
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
