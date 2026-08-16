import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Ripples + seta no canto inferior direito (retomada urgente).
class DashboardDayFocusRipplePainter extends CustomPainter {
  const DashboardDayFocusRipplePainter({
    required this.color,
    this.isDark = false,
  });

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.78, size.height * 0.92);
    final maxR = math.min(size.width, size.height) * 1.05;
    final baseAlpha = isDark ? 0.24 : 0.18;

    final glow = Paint()
      ..shader = ui.Gradient.radial(
        origin,
        maxR * 0.58,
        [
          color.withValues(alpha: baseAlpha * 0.85),
          color.withValues(alpha: 0),
        ],
      );
    canvas.drawCircle(origin, maxR * 0.58, glow);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 1; i <= 5; i++) {
      final t = i / 5;
      ringPaint.color = color.withValues(
        alpha: baseAlpha * (1.0 - t * 0.7),
      );
      canvas.drawCircle(origin, maxR * (0.16 + t * 0.58), ringPaint);
    }

    canvas.drawCircle(
      origin,
      3.4,
      Paint()..color = color.withValues(alpha: isDark ? 0.58 : 0.45),
    );

    // Seta curva saindo do núcleo → canto superior direito.
    final c1 = Offset(origin.dx + maxR * 0.28, origin.dy - maxR * 0.12);
    final c2 = Offset(size.width * 0.92, size.height * 0.42);
    final tip = Offset(size.width * 0.98, size.height * 0.22);

    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: isDark ? 0.5 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Tangente aproximada no fim da cúbica (c2 → tip).
    final angle = math.atan2(tip.dy - c2.dy, tip.dx - c2.dx);
    const head = 7.5;
    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - head * math.cos(angle - 0.48),
        tip.dy - head * math.sin(angle - 0.48),
      )
      ..lineTo(
        tip.dx - head * math.cos(angle + 0.48),
        tip.dy - head * math.sin(angle + 0.48),
      )
      ..close();
    canvas.drawPath(
      headPath,
      Paint()..color = color.withValues(alpha: isDark ? 0.55 : 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant DashboardDayFocusRipplePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
