import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/prontidao_display.dart';

/// Índice de prontidão (0–100) no centro; null mostra "--" com o anel vazio.
class RecoveryScoreRing extends StatelessWidget {
  const RecoveryScoreRing({
    super.key,
    required this.score,
    required this.color,
    this.size = 52,
  });

  final int? score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RecoveryRingPainter(score: score, color: color),
        child: Center(
          child: Text(
            score?.toString() ?? '--',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.26,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryRingPainter extends CustomPainter {
  _RecoveryRingPainter({required this.score, required this.color});

  final int? score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final background =
        Paint()
          ..color = color.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
    final foreground =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);
    final value = score;
    if (value == null) return;
    final sweep =
        (value.clamp(0, prontidaoEscalaMax) / prontidaoEscalaMax) *
        math.pi *
        2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RecoveryRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
