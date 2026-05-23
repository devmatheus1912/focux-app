import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight confetti burst for celebration overlays (Rive-free fallback).
class FxConfettiBurst extends StatefulWidget {
  const FxConfettiBurst({super.key, required this.color});

  final Color color;

  @override
  State<FxConfettiBurst> createState() => _FxConfettiBurstState();
}

class _FxConfettiBurstState extends State<FxConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(28, (i) {
      return _Particle(
        angle: rnd.nextDouble() * math.pi * 2,
        speed: 0.35 + rnd.nextDouble() * 0.65,
        size: 4 + rnd.nextDouble() * 6,
        hueShift: rnd.nextDouble() * 0.2,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.hueShift,
  });

  final double angle;
  final double speed;
  final double size;
  final double hueShift;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.color,
  });

  final double progress;
  final List<_Particle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    for (final p in particles) {
      final dist = p.speed * progress * size.shortestSide * 0.55;
      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist + progress * 40;
      final paint = Paint()
        ..color = Color.lerp(color, Colors.white, p.hueShift)!
            .withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 1.6),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
