import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_brand_tagline.dart';
import '../../../core/widgets/focux_official_logo.dart';

/// Splash Flutter — logo, hook unificado e barra de progresso limpa.
class CinematicSplashScene extends StatelessWidget {
  const CinematicSplashScene({
    super.key,
    required this.progress,
    required this.ambient,
    required this.entry,
    required this.fadeOut,
  });

  final double progress;
  final Animation<double> ambient;
  final Animation<double> entry;
  final Animation<double> fadeOut;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.sizeOf(context);
    final reduceMotion = reduceMotionOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([ambient, entry, fadeOut]),
      builder: (context, _) {
        final phase = ambient.value;
        final entryT =
            reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(entry.value.clamp(0.0, 1.0));

        return Opacity(
          opacity: fadeOut.value.clamp(0.0, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.06),
                      Opacity(
                        opacity: entryT,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            reduceMotion ? 0 : (1 - entryT) * 24,
                          ),
                          child: _SplashHeroMark(
                            phase: phase,
                            entry: entry.value,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity:
                            reduceMotion
                                ? 1
                                : Curves.easeOut.transform(
                                  (entry.value - 0.12).clamp(0.0, 1.0),
                                ),
                        child: const FocuxBrandTagline(center: true, fontSize: 14),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity:
                            reduceMotion
                                ? 1
                                : Curves.easeOut.transform(
                                  (entry.value - 0.28).clamp(0.0, 1.0),
                                ),
                        child: _LoadingRail(
                          progress: progress,
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SplashHeroMark extends StatelessWidget {
  const _SplashHeroMark({
    required this.phase,
    required this.entry,
    required this.reduceMotion,
  });

  final double phase;
  final double entry;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    const logoWidth = 200.0;
    final floatY = reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 4;
    final scale =
        reduceMotion
            ? 1.0
            : 0.92 +
                Curves.easeOutCubic.transform(entry.clamp(0.0, 1.0)) * 0.08;

    return Transform.translate(
      offset: Offset(0, floatY),
      child: Transform.scale(
        scale: scale,
        child: const FocuxOfficialLogo.full(width: logoWidth),
      ),
    );
  }
}

class _LoadingRail extends StatelessWidget {
  const _LoadingRail({required this.progress, required this.primary});

  final double progress;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Carregando ${(clamped * 100).round()} por cento',
      value: '${(clamped * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FocuxBrandCopy.splashLoading.toUpperCase(),
            style: AppTypography.inter(
              color: primary.withValues(alpha: 0.88),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 4.6,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, 280.0);
              final fillWidth = width * clamped;

              return SizedBox(
                width: width,
                height: 4,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (fillWidth > 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        width: fillWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: primary,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
