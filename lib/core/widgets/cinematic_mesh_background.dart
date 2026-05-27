import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/tokens_strip.dart';

/// Shared cinematic mesh — TOKENS STRIP Liquid Glass backdrop.
class CinematicMeshBackground extends StatelessWidget {
  const CinematicMeshBackground({
    super.key,
    required this.child,
    this.showCenterGlow = true,
    this.showCornerGlow = true,
    this.forceDark = false,
    this.flatBackground = false,
  });

  final Widget child;
  final bool showCenterGlow;
  final bool showCornerGlow;
  final bool forceDark;
  final bool flatBackground;

  @override
  Widget build(BuildContext context) {
    final isLight =
        !forceDark && Theme.of(context).brightness == Brightness.light;
    final primary = Theme.of(context).colorScheme.primary;
    final cornerGlow = isLight ? BrandPalette.accent(primary) : TokensStrip.neonGlow;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color:
              flatBackground
                  ? (isLight ? TokensStrip.lightMeshC : TokensStrip.cinematicBg)
                  : null,
          decoration:
              flatBackground
                  ? null
                  : BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.85),
                        radius: 1.45,
                        colors:
                            isLight
                                ? const [
                                  TokensStrip.lightMeshA,
                                  TokensStrip.lightMeshB,
                                  TokensStrip.lightMeshC,
                                ]
                                : const [
                                  Color(0xFF0D2830),
                                  Color(0xFF0B0E14),
                                  TokensStrip.cinematicBg,
                                ],
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
        ),
        CustomPaint(
          painter: CinematicGridPainter(light: isLight),
          size: Size.infinite,
        ),
        if (showCornerGlow) ...[
          Positioned(
            top: -100,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cornerGlow.withValues(alpha: isLight ? 0.10 : 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: isLight ? 0.05 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (showCenterGlow)
          Align(
            alignment: const Alignment(0, -0.20),
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: isLight ? 0.10 : 0.18),
                      TokensStrip.neonGlow.withValues(
                        alpha: isLight ? 0.04 : 0.08,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 1.0],
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
                  ? TokensStrip.neonGlow.withValues(alpha: 0.05)
                  : TokensStrip.neonGlow.withValues(alpha: 0.07)
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
