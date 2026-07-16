import 'package:flutter/material.dart';

class AnimatedStrikethroughText extends StatelessWidget {
  final Widget child;
  final bool isStruckThrough;
  final Duration duration;
  final Color strikethroughColor;

  const AnimatedStrikethroughText({
    super.key,
    required this.child,
    required this.isStruckThrough,
    this.duration = const Duration(milliseconds: 800),
    required this.strikethroughColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // The actual content
          child,
          // The animated strikethrough line
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isStruckThrough ? 1.0 : 0.0),
                duration: duration,
                curve: Curves.easeInOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 1.5,
                      color: strikethroughColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
