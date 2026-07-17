import 'package:flutter/material.dart';

class StrikethroughPainter extends CustomPainter {
  final double progress;
  final Color color;

  StrikethroughPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Calculate vertical center
    final y = size.height / 2;
    // Draw line from left to right based on progress
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(StrikethroughPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class AnimatedStrikethroughText extends StatefulWidget {
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
  State<AnimatedStrikethroughText> createState() =>
      _AnimatedStrikethroughTextState();
}

class _AnimatedStrikethroughTextState extends State<AnimatedStrikethroughText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize exactly at the target value to prevent any mount animation
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isStruckThrough ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(AnimatedStrikethroughText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update duration if it changed
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    
    // Play animation if state changed
    if (widget.isStruckThrough != oldWidget.isStruckThrough) {
      if (widget.isStruckThrough) {
        // Force start from current value to 1.0 (prevents jump if recreating)
        _controller.forward();
      } else {
        // Force start from current value to 0.0
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: StrikethroughPainter(
            _controller.value,
            widget.strikethroughColor,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
