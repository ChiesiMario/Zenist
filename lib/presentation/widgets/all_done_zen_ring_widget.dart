import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AllDoneZenRingWidget extends StatefulWidget {
  final String message;
  final String subtitle;

  const AllDoneZenRingWidget({
    super.key,
    required this.message,
    required this.subtitle,
  });

  @override
  State<AllDoneZenRingWidget> createState() => _AllDoneZenRingWidgetState();
}

class _AllDoneZenRingWidgetState extends State<AllDoneZenRingWidget> with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _glowController;
  late AnimationController _textFadeController;
  
  late Animation<double> _drawAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutCubic,
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.5).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // 1. Draw the ring
    await _drawController.forward();
    // 2. Fade in the text
    _textFadeController.forward();
    // 3. Start breathing glow
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _drawController.dispose();
    _glowController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final baseColor = theme.colorScheme.primary;
    final successColor = Colors.green.shade500;

    return Container(
      padding: const EdgeInsets.only(top: 78.0, bottom: 48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_drawAnimation, _glowAnimation]),
            builder: (context, child) {
              // Interpolate color from base to green based on draw progress
              final currentColor = Color.lerp(baseColor, successColor, _drawAnimation.value) ?? successColor;

              return SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _ZenRingPainter(
                    progress: _drawAnimation.value,
                    glowProgress: _drawController.isCompleted ? _glowAnimation.value : 0.0,
                    color: currentColor,
                    strokeWidth: 4.0,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _textFadeController,
            child: Column(
              children: [
                Text(
                  widget.message,
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenRingPainter extends CustomPainter {
  final double progress;
  final double glowProgress;
  final Color color;
  final double strokeWidth;

  _ZenRingPainter({
    required this.progress,
    required this.glowProgress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track (optional, very faint)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;

      // Draw neon glow (only when fully drawn, or continuously if desired)
      if (progress >= 1.0 && glowProgress > 0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowProgress * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.0 // Slightly thicker
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      // Draw crisp main stroke
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ZenRingPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.glowProgress != glowProgress ||
           oldDelegate.color != color;
  }
}
