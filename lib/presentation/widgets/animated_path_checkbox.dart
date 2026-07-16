import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedPathCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color checkColor;
  final Duration duration;

  const AnimatedPathCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    required this.checkColor,
    this.duration = const Duration(milliseconds: 600), // Slower for zen feel
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onChanged == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: value ? 1.0 : 0.0, end: value ? 1.0 : 0.0),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return CustomPaint(
              size: const Size(16, 16), // Match title font size
              painter: _CheckboxPainter(
                progress: progress,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                checkColor: checkColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color checkColor;

  _CheckboxPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Background
    final bgPaint = Paint()
      ..color = Color.lerp(Colors.transparent, activeColor, progress)!
      ..style = PaintingStyle.fill;
    
    // Border
    final borderPaint = Paint()
      ..color = Color.lerp(inactiveColor, activeColor, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw checkmark path
    if (progress > 0) {
      final checkPaint = Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      // standard checkmark coordinates inside the box
      path.moveTo(size.width * 0.25, size.height * 0.5);
      path.lineTo(size.width * 0.45, size.height * 0.7);
      path.lineTo(size.width * 0.75, size.height * 0.3);

      for (final metric in path.computeMetrics()) {
        final extractPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(extractPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckboxPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor ||
           oldDelegate.checkColor != checkColor;
  }
}
