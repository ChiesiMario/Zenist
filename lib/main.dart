import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
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
    return MaterialApp(
      title: 'Zenist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const TodoListPage(),
    );
  }
}
