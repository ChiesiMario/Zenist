import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'presentation/pages/todo_list_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

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

class ZenistApp extends ConsumerWidget {
  const ZenistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      home: const TodoListPage(),
    );
  }
}
