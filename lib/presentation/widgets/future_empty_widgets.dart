import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// ----------------------------------------------------------------------
// Base empty widget to handle text and padding consistently
// ----------------------------------------------------------------------
class _BaseFutureEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget animationWidget;

  const _BaseFutureEmptyWidget({
    required this.title,
    required this.subtitle,
    required this.animationWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 78.0, bottom: 48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          animationWidget,
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.large.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.w400,
              fontSize: 12.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 1. Upcoming - Dashed Ring
// ----------------------------------------------------------------------
class UpcomingEmptyWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  const UpcomingEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<UpcomingEmptyWidget> createState() => _UpcomingEmptyWidgetState();
}

class _UpcomingEmptyWidgetState extends State<UpcomingEmptyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseFutureEmptyWidget(
      title: widget.title,
      subtitle: widget.subtitle,
      animationWidget: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * pi,
              child: CustomPaint(
                painter: _DashedRingPainter(
                  color: ShadTheme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.6),
                  strokeWidth: 3.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dashCount = 12;
    final dashLength = (2 * pi * radius) / (dashCount * 2);
    final dashAngle = dashLength / radius;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * 2 * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ----------------------------------------------------------------------
// 2. Someday - Partial Arc
// ----------------------------------------------------------------------
class SomedayEmptyWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  const SomedayEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<SomedayEmptyWidget> createState() => _SomedayEmptyWidgetState();
}

class _SomedayEmptyWidgetState extends State<SomedayEmptyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseFutureEmptyWidget(
      title: widget.title,
      subtitle: widget.subtitle,
      animationWidget: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: -pi / 4, // rotate slightly
              child: CustomPaint(
                painter: _PartialArcPainter(
                  progress:
                      0.6 +
                      (_controller.value *
                          0.2), // pulses between 60% and 80% of a circle
                  color: ShadTheme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                  strokeWidth: 4.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PartialArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _PartialArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PartialArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ----------------------------------------------------------------------
// 3. Anytime - Pulsing Ripple
// ----------------------------------------------------------------------
class AnytimeEmptyWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  const AnytimeEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<AnytimeEmptyWidget> createState() => _AnytimeEmptyWidgetState();
}

class _AnytimeEmptyWidgetState extends State<AnytimeEmptyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseFutureEmptyWidget(
      title: widget.title,
      subtitle: widget.subtitle,
      animationWidget: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _RipplePainter(
                progress: _controller.value,
                color: ShadTheme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Center dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, dotPaint);

    // Ripple
    final rippleRadius = maxRadius * progress;
    final rippleOpacity = 1.0 - progress;

    if (rippleRadius > 4.0) {
      final ripplePaint = Paint()
        ..color = color.withValues(alpha: rippleOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ----------------------------------------------------------------------
// 4. Today - Breathing Ring
// ----------------------------------------------------------------------
class TodayEmptyWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  const TodayEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<TodayEmptyWidget> createState() => _TodayEmptyWidgetState();
}

class _TodayEmptyWidgetState extends State<TodayEmptyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseFutureEmptyWidget(
      title: widget.title,
      subtitle: widget.subtitle,
      animationWidget: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final curvedProgress = Curves.easeInOutSine.transform(
              _controller.value,
            );
            return CustomPaint(
              painter: _BreathingRingPainter(
                progress: curvedProgress,
                color: ShadTheme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BreathingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BreathingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final minRadius = 36.0;
    final maxRadius = 40.0;
    final currentRadius = minRadius + (maxRadius - minRadius) * progress;

    final currentOpacity = 0.8 - (0.6 * progress);

    final currentStroke = 3.0 - (0.5 * progress);

    final paint = Paint()
      ..color = color.withValues(alpha: currentOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentStroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _BreathingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
