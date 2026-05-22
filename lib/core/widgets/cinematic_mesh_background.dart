import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Shared cinematic mesh used on login, splash, and premium app chrome.
class CinematicMeshBackground extends StatelessWidget {
  const CinematicMeshBackground({
    super.key,
    required this.child,
    this.showCenterGlow = true,
    this.showCornerGlow = true,
    this.forceDark = false,
  });

  final Widget child;
  final bool showCenterGlow;
  final bool showCornerGlow;

  /// When true, always render the dark login mesh regardless of theme.
  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    final isLight =
        !forceDark && Theme.of(context).brightness == Brightness.light;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.85),
              radius: 1.35,
              colors:
                  isLight
                      ? const [
                        Color(0xFFE4F7F7),
                        Color(0xFFF4F7F8),
                        Color(0xFFECF2F4),
                      ]
                      : const [
                        Color(0xFF0D2830),
                        Color(0xFF0A1F24),
                        Color(0xFF080C10),
                      ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        CustomPaint(
          painter: CinematicGridPainter(light: isLight),
          size: Size.infinite,
        ),
        if (showCornerGlow)
          Positioned(
            top: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EagleTokens.brandAccent.withValues(
                        alpha: isLight ? 0.07 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
        if (showCenterGlow)
          Align(
            alignment: const Alignment(0, -0.22),
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1EC8C8).withValues(
                        alpha: isLight ? 0.08 : 0.14,
                      ),
                      EagleTokens.brandAccent.withValues(
                        alpha: isLight ? 0.03 : 0.06,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class CinematicGridPainter extends CustomPainter {
  const CinematicGridPainter({this.light = false});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              light
                  ? EagleTokens.brandAccent.withValues(alpha: 0.045)
                  : EagleTokens.brandAccent.withValues(alpha: 0.06)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CinematicGridPainter oldDelegate) =>
      oldDelegate.light != light;
}
