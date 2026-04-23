import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class FxLogo extends StatelessWidget {
  final double size;

  const FxLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EagleTokens.brandAccent,
            EagleTokens.brand,
            EagleTokens.brandDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(size * (11 / 40)),
      ),
      child: CustomPaint(
        painter: _FxTargetPainter(),
      ),
    );
  }
}

class _FxTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 40x40 coordinate system scaled to size
    final scale = size.width / 40.0;
    canvas.scale(scale, scale);

    final fgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer ring
    fgPaint.strokeWidth = 1.3;
    fgPaint.color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(20, 20), 13.5, fgPaint);

    // Inner ring
    fgPaint.color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(20, 20), 9, fgPaint);

    // Bold X
    fgPaint.strokeWidth = 3.2;
    fgPaint.color = Colors.white;
    canvas.drawLine(const Offset(13, 13), const Offset(27, 27), fgPaint);
    canvas.drawLine(const Offset(27, 13), const Offset(13, 27), fgPaint);

    // Center dot
    canvas.drawCircle(const Offset(20, 20), 1.8, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
