import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/brand_tint.dart';
import '../theme/tokens_strip.dart';

/// Shared cinematic mesh — TOKENS STRIP Liquid Glass backdrop (sem grade).
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
    // Estilo Cinematográfico: a malha sente a paleta do personal.
    final marca = BrandTint.maybeOf(context);
    final tinge = marca != null && marca.estilo.tingeFundo;
    final cornerGlow =
        tinge
            ? marca.secundaria
            : isLight
            ? BrandPalette.accent(primary)
            : TokensStrip.neonGlow;
    final malhaClara = [
      TokensStrip.lightMeshA,
      TokensStrip.lightMeshB,
      TokensStrip.lightMeshC,
    ];
    final malhaEscura = [
      const Color(0xFF0D2830),
      const Color(0xFF0B0E14),
      TokensStrip.cinematicBg,
    ];
    final malha = tinge
        ? [
          Color.lerp(
            isLight ? malhaClara[0] : malhaEscura[0],
            marca.primaria,
            isLight ? 0.12 : 0.38,
          )!,
          Color.lerp(
            isLight ? malhaClara[1] : malhaEscura[1],
            marca.secundaria,
            isLight ? 0.05 : 0.12,
          )!,
          isLight ? malhaClara[2] : malhaEscura[2],
        ]
        : (isLight ? malhaClara : malhaEscura);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final liso = flatBackground || reduceMotion;
    final comBrilhoCanto = showCornerGlow && !reduceMotion;
    final comBrilhoCentro = showCenterGlow && !reduceMotion;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color:
              liso
                  ? (isLight ? TokensStrip.lightMeshC : TokensStrip.cinematicBg)
                  : null,
          decoration:
              liso
                  ? null
                  : BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.85),
                        radius: 1.45,
                        colors: malha,
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
        ),
        if (comBrilhoCanto) ...[
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
                      cornerGlow.withValues(alpha: isLight ? 0.14 : 0.16),
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
                      primary.withValues(alpha: isLight ? 0.08 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (comBrilhoCentro)
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
