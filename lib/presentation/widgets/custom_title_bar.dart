import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Avoid using Theme.of(context) here because ShadApp might not provide a Material Theme
    // at this high level in the widget tree.
    return const WindowCaption(
      brightness: Brightness.light,
      backgroundColor: Colors.transparent,
      title: SizedBox.shrink(),
    );
  }
}
