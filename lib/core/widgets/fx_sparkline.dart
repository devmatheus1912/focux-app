import 'package:flutter/material.dart';

class FxSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double width;
  final double height;
  final double strokeWidth;
  final bool fill;

  const FxSparkline({
    super.key,
    required this.data,
    required this.color,
    this.width = 56,
    this.height = 22,
    this.strokeWidth = 2.0,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool fill;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.strokeWidth,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    
    // Add some padding so the stroke doesn't get cut off
    final padding = strokeWidth / 2;
    final w = size.width - (padding * 2);
    final h = size.height - (padding * 2);

    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final path = Path();
    final stepX = w / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalizedY = (data[i] - minVal) / (maxVal - minVal);
      // Invert Y because canvas Y goes down
      final y = padding + (h - (normalizedY * h));
      final x = padding + (i * stepX);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (!fill) return;

    // Optional: add a subtle gradient fill under the line
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(padding + w, size.height)
      ..lineTo(padding, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.fill != fill;
  }
}
