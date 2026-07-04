import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/todo_list_page.dart';

void main() {
  runApp(
    // ProviderScope 讓 Riverpod 能夠管理全域狀態
    const ProviderScope(
      child: ZenistApp(),
    ),
  );
}

class ZenistApp extends StatelessWidget {
  const ZenistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Zenist',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        colorScheme: const ShadZincColorScheme.light(
          background: Color(0xFFFAFAFA), // 極淡灰背景，突顯卡片
        ),
        brightness: Brightness.light,
        textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),
      ),
      home: const TodoListPage(),
    );
  }
}
