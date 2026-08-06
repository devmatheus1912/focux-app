import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Grade cinematográfica leve para superfícies pré-login / auth.
class AuthGridPainter extends CustomPainter {
  const AuthGridPainter({this.alpha = 0.045, this.step = 30});

  final double alpha;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = EagleTokens.brandAccent.withValues(alpha: alpha)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant AuthGridPainter old) =>
      old.alpha != alpha || old.step != step;
}
