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
    final padding = strokeWidth / 2;

    if (data.isEmpty || data.every((value) => value <= 0)) {
      _paintEmptyTrack(canvas, size, padding);
      return;
    }

    if (data.length < 2) {
      _paintSinglePoint(canvas, size, padding);
      return;
    }

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);

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

    // End dot — matches design (r=2.5 circle at last data point)
    final lastNorm = (data.last - minVal) / (maxVal - minVal);
    final lastX = padding + w;
    final lastY = padding + (h - (lastNorm * h));
    canvas.drawCircle(
      Offset(lastX, lastY),
      2.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    if (!fill) return;

    // Optional: add a subtle gradient fill under the line
    final fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath =
        Path.from(path)
          ..lineTo(padding + w, size.height)
          ..lineTo(padding, size.height)
          ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  void _paintSinglePoint(Canvas canvas, Size size, double padding) {
    final x = size.width / 2;
    final y = size.height / 2;
    canvas.drawCircle(
      Offset(x, y),
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    final trackPaint =
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(padding, y),
      Offset(size.width - padding, y),
      trackPaint,
    );
  }

  void _paintEmptyTrack(Canvas canvas, Size size, double padding) {
    final trackPaint =
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final y = size.height - padding - 1;
    canvas.drawLine(
      Offset(padding, y),
      Offset(size.width - padding, y),
      trackPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fill != fill;
  }
}
