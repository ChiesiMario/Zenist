import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          '設置',
          style: ShadTheme.of(context).textTheme.h4,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ShadButton.ghost(
          child: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(
          color: ShadTheme.of(context).colorScheme.foreground,
        ),
      ),
      body: Center(
        child: Text(
          '這裡目前還是空的。',
          style: ShadTheme.of(context).textTheme.p.copyWith(
            color: ShadTheme.of(context).colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
