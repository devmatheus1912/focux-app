import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/tokens_strip.dart';

/// Shared cinematic mesh — TOKENS STRIP Liquid Glass backdrop.
class CinematicMeshBackground extends StatefulWidget {
  const CinematicMeshBackground({
    super.key,
    required this.child,
    this.showCenterGlow = true,
    this.showCornerGlow = true,
    this.forceDark = false,
    this.flatBackground = false,
    this.showGrid = true,
    this.animateGridIn = true,
  });

  final Widget child;
  final bool showCenterGlow;
  final bool showCornerGlow;
  final bool forceDark;
  final bool flatBackground;
  final bool showGrid;
  final bool animateGridIn;

  @override
  State<CinematicMeshBackground> createState() =>
      _CinematicMeshBackgroundState();
}

class _CinematicMeshBackgroundState extends State<CinematicMeshBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _gridFadeCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.showGrid && widget.animateGridIn) {
      _gridFadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gridFadeCtrl?.forward();
      });
    }
  }

  @override
  void dispose() {
    _gridFadeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight =
        !widget.forceDark && Theme.of(context).brightness == Brightness.light;
    final primary = Theme.of(context).colorScheme.primary;
    final cornerGlow =
        isLight ? BrandPalette.accent(primary) : TokensStrip.neonGlow;

    Widget? gridLayer;
    if (widget.showGrid) {
      final grid = CustomPaint(
        painter: _CinematicGridPainter(light: isLight),
        size: Size.infinite,
      );
      gridLayer =
          _gridFadeCtrl != null
              ? FadeTransition(
                opacity: CurvedAnimation(
                  parent: _gridFadeCtrl!,
                  curve: Curves.easeOutCubic,
                ),
                child: grid,
              )
              : grid;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color:
              widget.flatBackground
                  ? (isLight ? TokensStrip.lightMeshC : TokensStrip.cinematicBg)
                  : null,
          decoration:
              widget.flatBackground
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
        if (gridLayer != null) gridLayer,
        if (widget.showCornerGlow) ...[
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
        if (widget.showCenterGlow)
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
        widget.child,
      ],
    );
  }
}

class _CinematicGridPainter extends CustomPainter {
  const _CinematicGridPainter({this.light = false});

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
  bool shouldRepaint(covariant _CinematicGridPainter oldDelegate) =>
      oldDelegate.light != light;
}
