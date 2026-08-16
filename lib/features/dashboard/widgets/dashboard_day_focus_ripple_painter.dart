import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Radar suave no canto — ripples + seta (retomada urgente).
class DashboardDayFocusRipplePainter extends CustomPainter {
  const DashboardDayFocusRipplePainter({
    required this.color,
    this.isDark = false,
  });

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Âncora no canto inferior direito, levemente para fora do card.
    final origin = Offset(size.width * 0.72, size.height * 0.78);
    final span = math.max(size.width, size.height);

    // Glow amplo e bem diluído (não mancha o texto).
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        origin,
        span * 0.72,
        [
          color.withValues(alpha: isDark ? 0.20 : 0.11),
          color.withValues(alpha: isDark ? 0.06 : 0.035),
          color.withValues(alpha: 0),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(origin, span * 0.72, glowPaint);

    // Anéis: finos, espaçamento regular, fade externo.
    final ringCount = 6;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 1.05 : 0.9;

    for (var i = 1; i <= ringCount; i++) {
      final t = i / ringCount;
      final radius = span * (0.12 + t * 0.55);
      final alpha = (isDark ? 0.28 : 0.20) * (1.0 - t * 0.78);
      ringPaint.color = color.withValues(alpha: alpha.clamp(0.02, 1.0));
      canvas.drawCircle(origin, radius, ringPaint);
    }

    // Núcleo sólido pequeno.
    canvas.drawCircle(
      origin,
      2.8,
      Paint()..color = color.withValues(alpha: isDark ? 0.72 : 0.55),
    );
    canvas.drawCircle(
      origin,
      5.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = color.withValues(alpha: isDark ? 0.35 : 0.22),
    );

    // Seta: arco limpo origin → topo-direita.
    final tip = Offset(size.width * 0.96, size.height * 0.08);
    final ctrl = Offset(
      origin.dx + (tip.dx - origin.dx) * 0.55,
      origin.dy - span * 0.38,
    );

    final arrowPath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color.withValues(alpha: isDark ? 0.55 : 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round,
    );

    // Cabeça alinhada à tangente final (ctrl → tip).
    final angle = math.atan2(tip.dy - ctrl.dy, tip.dx - ctrl.dx);
    const headLen = 8.0;
    const headSpread = 0.52;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - headLen * math.cos(angle - headSpread),
        tip.dy - headLen * math.sin(angle - headSpread),
      )
      ..lineTo(
        tip.dx - headLen * 0.55 * math.cos(angle),
        tip.dy - headLen * 0.55 * math.sin(angle),
      )
      ..lineTo(
        tip.dx - headLen * math.cos(angle + headSpread),
        tip.dy - headLen * math.sin(angle + headSpread),
      )
      ..close();
    canvas.drawPath(
      head,
      Paint()..color = color.withValues(alpha: isDark ? 0.62 : 0.44),
    );
  }

  @override
  bool shouldRepaint(covariant DashboardDayFocusRipplePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}
