import 'package:flutter/material.dart';

/// FxIcon — stroke-based monoline icon set (ported from design `tokens.jsx`).
///
/// This intentionally avoids Material icons so the app matches the Handoff spec.
class FxIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final double strokeWidth;

  const FxIcon({
    super.key,
    required this.name,
    required this.color,
    this.size = 20,
    this.strokeWidth = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FxIconPainter(
          name: name,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _FxIconPainter extends CustomPainter {
  final String name;
  final Color color;
  final double strokeWidth;

  const _FxIconPainter({
    required this.name,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // 24x24 coordinate system like the original SVGs
    final s = size.shortestSide;
    final scale = s / 24.0;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(scale, scale);

    switch (name) {
      case 'home':
        canvas.drawPath(
          Path()
            ..moveTo(3, 11)
            ..lineTo(12, 4)
            ..lineTo(21, 11)
            ..lineTo(21, 20)
            ..cubicTo(21, 21.1046, 20.1046, 22, 19, 22)
            ..lineTo(15, 22)
            ..lineTo(15, 16)
            ..lineTo(9, 16)
            ..lineTo(9, 22)
            ..lineTo(5, 22)
            ..cubicTo(3.8954, 22, 3, 21.1046, 3, 20)
            ..close(),
          paint,
        );
        break;

      case 'users':
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: const Offset(9, 8), radius: 4)),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(2, 21)
            ..lineTo(2, 20)
            ..cubicTo(2, 16.6863, 4.6863, 14, 8, 14)
            ..lineTo(10, 14)
            ..cubicTo(13.3137, 14, 16, 16.6863, 16, 20)
            ..lineTo(16, 21),
          paint,
        );
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: const Offset(17, 6), radius: 3)),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(22, 16)
            ..lineTo(22, 15)
            ..cubicTo(22, 12.7909, 20.2091, 11, 18, 11)
            ..lineTo(17, 11),
          paint,
        );
        break;

      case 'dumbbell':
        canvas.drawLine(const Offset(4, 9), const Offset(4, 15), paint);
        canvas.drawLine(const Offset(2, 11), const Offset(2, 13), paint);
        canvas.drawLine(const Offset(20, 9), const Offset(20, 15), paint);
        canvas.drawLine(const Offset(22, 11), const Offset(22, 13), paint);
        canvas.drawPath(
          Path()..addRect(const Rect.fromLTWH(6, 8, 3, 8)),
          paint,
        );
        canvas.drawPath(
          Path()..addRect(const Rect.fromLTWH(15, 8, 3, 8)),
          paint,
        );
        canvas.drawLine(const Offset(9, 12), const Offset(15, 12), paint);
        break;

      case 'coin':
        canvas.drawPath(
          Path()..addOval(const Rect.fromLTWH(4, 3, 16, 6)),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 6)
            ..lineTo(4, 12)
            ..cubicTo(4, 13.7, 7.6, 15, 12, 15)
            ..cubicTo(16.4, 15, 20, 13.7, 20, 12)
            ..lineTo(20, 6),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 12)
            ..lineTo(4, 18)
            ..cubicTo(4, 19.7, 7.6, 21, 12, 21)
            ..cubicTo(16.4, 21, 20, 19.7, 20, 18)
            ..lineTo(20, 12),
          paint,
        );
        break;

      case 'spark':
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(13.9, 8.1)
            ..lineTo(19, 10)
            ..lineTo(13.9, 11.9)
            ..lineTo(12, 17)
            ..lineTo(10.1, 11.9)
            ..lineTo(5, 10)
            ..lineTo(10.1, 8.1)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(19, 3)
            ..lineTo(19.9, 5.1)
            ..lineTo(22, 6)
            ..lineTo(19.9, 6.9)
            ..lineTo(19, 9)
            ..lineTo(18.1, 6.9)
            ..lineTo(16, 6)
            ..lineTo(18.1, 5.1)
            ..close(),
          paint,
        );
        break;

      case 'search':
        canvas.drawCircle(const Offset(11, 11), 6.5, paint);
        canvas.drawLine(const Offset(16, 16), const Offset(21, 21), paint);
        break;

      case 'help':
        // `?` outline — o poço circular fica no ShellHeaderIconButton, não no glifo.
        canvas.drawPath(
          Path()
            ..moveTo(7.6, 9.0)
            ..cubicTo(7.6, 5.7, 9.55, 3.7, 12, 3.7)
            ..cubicTo(15.05, 3.7, 17.1, 6.15, 17.1, 9.05)
            ..cubicTo(17.1, 11.55, 14.85, 12.75, 13.05, 13.95)
            ..cubicTo(12.35, 14.4, 12, 15.15, 12, 16.35),
          paint,
        );
        canvas.drawCircle(const Offset(12, 19.55), 1.05, paint);
        break;

      case 'bell':
        canvas.drawPath(
          Path()
            ..moveTo(6, 8)
            ..cubicTo(6, 4.6863, 8.6863, 2, 12, 2)
            ..cubicTo(15.3137, 2, 18, 4.6863, 18, 8)
            ..cubicTo(18, 15, 21, 15, 21, 17)
            ..lineTo(3, 17)
            ..cubicTo(3, 15, 6, 15, 6, 8),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 21)
            ..cubicTo(10, 22.1046, 10.8954, 23, 12, 23)
            ..cubicTo(13.1046, 23, 14, 22.1046, 14, 21),
          paint,
        );
        break;

      case 'circle-check':
        canvas.drawCircle(const Offset(12, 12), 9, paint);
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(11, 15)
            ..lineTo(16, 9),
          paint,
        );
        break;

      case 'alert-triangle':
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(22, 20)
            ..lineTo(2, 20)
            ..close(),
          paint,
        );
        canvas.drawLine(const Offset(12, 9), const Offset(12, 13), paint);
        canvas.drawLine(const Offset(12, 17), const Offset(12, 17.1), paint);
        break;

      case 'flame':
        canvas.drawPath(
          Path()
            ..moveTo(12, 22)
            ..cubicTo(7, 20, 5, 16, 7, 12)
            ..cubicTo(8, 9, 11, 8, 10, 3)
            ..cubicTo(15, 6, 19, 11, 18, 16)
            ..cubicTo(17, 20, 15, 21, 12, 22)
            ..close(),
          paint,
        );
        break;

      case 'dollar-sign':
        canvas.drawLine(const Offset(12, 3), const Offset(12, 21), paint);
        canvas.drawPath(
          Path()
            ..moveTo(17, 7)
            ..cubicTo(14, 5, 8, 5, 8, 9)
            ..cubicTo(8, 13, 17, 11, 17, 16)
            ..cubicTo(17, 20, 10, 20, 7, 17),
          paint,
        );
        break;

      case 'plus':
        canvas.drawLine(const Offset(12, 5), const Offset(12, 19), paint);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), paint);
        break;

      case 'x':
        canvas.drawLine(const Offset(7, 7), const Offset(17, 17), paint);
        canvas.drawLine(const Offset(17, 7), const Offset(7, 17), paint);
        break;

      case 'calendar':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5, 18, 16),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.drawLine(const Offset(3, 9), const Offset(21, 9), paint);
        canvas.drawLine(const Offset(8, 3), const Offset(8, 7), paint);
        canvas.drawLine(const Offset(16, 3), const Offset(16, 7), paint);
        break;

      case 'chat':
        canvas.drawPath(
          Path()
            ..moveTo(21, 12)
            ..cubicTo(21, 7.5817, 17.4183, 4, 13, 4)
            ..cubicTo(8.5817, 4, 5, 7.5817, 5, 12)
            ..cubicTo(5, 13.3687, 5.343, 14.658, 5.948, 15.791)
            ..lineTo(3, 21)
            ..lineTo(8.209, 18.052)
            ..cubicTo(9.342, 18.657, 10.6313, 19, 12, 19)
            ..cubicTo(16.4183, 19, 20, 15.4183, 20, 11)
            ..close(),
          paint,
        );
        break;

      case 'message-circle':
        canvas.drawPath(
          Path()
            ..moveTo(21, 11.5)
            ..cubicTo(21, 16.2, 17, 20, 12, 20)
            ..cubicTo(10.7, 20, 9.5, 19.8, 8.4, 19.3)
            ..lineTo(3, 21)
            ..lineTo(4.7, 15.9)
            ..cubicTo(4.2, 14.6, 4, 13.1, 4, 11.5)
            ..cubicTo(4, 6.8, 8, 3, 13, 3)
            ..cubicTo(17.4, 3, 21, 6.8, 21, 11.5)
            ..close(),
          paint,
        );
        break;

      case 'trend':
        canvas.drawPath(
          Path()
            ..moveTo(3, 17)
            ..lineTo(9, 11)
            ..lineTo(13, 15)
            ..lineTo(21, 7),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14, 7)
            ..lineTo(21, 7)
            ..lineTo(21, 14),
          paint,
        );
        break;

      case 'zap':
        canvas.drawPath(
          Path()
            ..moveTo(13, 2)
            ..lineTo(4, 14)
            ..lineTo(11, 14)
            ..lineTo(10, 22)
            ..lineTo(20, 9)
            ..lineTo(13, 9)
            ..close(),
          paint,
        );
        break;

      case 'route':
        canvas.drawCircle(const Offset(6, 6), 2.5, paint);
        canvas.drawCircle(const Offset(18, 18), 2.5, paint);
        canvas.drawPath(
          Path()
            ..moveTo(8, 6)
            ..cubicTo(18, 6, 6, 18, 16, 18),
          paint,
        );
        break;

      case 'target':
        canvas.drawCircle(const Offset(12, 12), 8.5, paint);
        canvas.drawCircle(const Offset(12, 12), 4.5, paint);
        canvas.drawCircle(
          const Offset(12, 12),
          1.6,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        break;

      case 'chevron-right':
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19),
          paint,
        );
        break;

      case 'arrow-left':
        canvas.drawPath(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(21, 12),
          paint,
        );
        break;

      case 'sun':
        canvas.drawCircle(const Offset(12, 12), 4, paint);
        for (final p in const [
          [12.0, 2.0, 12.0, 5.0],
          [12.0, 19.0, 12.0, 22.0],
          [2.0, 12.0, 5.0, 12.0],
          [19.0, 12.0, 22.0, 12.0],
          [4.9, 4.9, 7.0, 7.0],
          [17.0, 17.0, 19.1, 19.1],
          [19.1, 4.9, 17.0, 7.0],
          [7.0, 17.0, 4.9, 19.1],
        ]) {
          canvas.drawLine(Offset(p[0], p[1]), Offset(p[2], p[3]), paint);
        }
        break;

      case 'moon':
        canvas.drawPath(
          Path()
            ..moveTo(21, 13)
            ..cubicTo(19.7, 18, 14.5, 21, 9.5, 19.5)
            ..cubicTo(4.5, 18, 1.8, 12.7, 3.5, 7.8)
            ..cubicTo(4.4, 5.1, 6.5, 3, 9, 2)
            ..cubicTo(8.1, 5.5, 9.7, 9.4, 13, 11.2)
            ..cubicTo(15.5, 12.6, 18.4, 12.8, 21, 13)
            ..close(),
          paint,
        );
        break;

      case 'pix':
        canvas.drawPath(
          Path()
            ..moveTo(5, 5)
            ..lineTo(12, 12)
            ..lineTo(19, 5),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 19)
            ..lineTo(12, 12)
            ..lineTo(19, 19),
          paint,
        );
        break;

      case 'article':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 3, 14, 18),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.drawLine(const Offset(8, 8), const Offset(16, 8), paint);
        canvas.drawLine(const Offset(8, 12), const Offset(16, 12), paint);
        canvas.drawLine(const Offset(8, 16), const Offset(13, 16), paint);
        break;

      case 'star':
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(14.5, 9)
            ..lineTo(21, 9.5)
            ..lineTo(16, 13.5)
            ..lineTo(17.5, 20)
            ..lineTo(12, 16.5)
            ..lineTo(6.5, 20)
            ..lineTo(8, 13.5)
            ..lineTo(3, 9.5)
            ..lineTo(9.5, 9)
            ..close(),
          paint,
        );
        break;

      default:
        // fallback circle
        canvas.drawCircle(const Offset(12, 12), 9, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FxIconPainter oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
