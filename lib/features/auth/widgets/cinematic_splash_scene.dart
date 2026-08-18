import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_brand_tagline.dart';
import '../../../core/widgets/focux_official_logo.dart';

/// Splash Flutter — continuidade com nativo (ícone → lockup) + barra limpa.
class CinematicSplashScene extends StatelessWidget {
  const CinematicSplashScene({
    super.key,
    required this.progress,
    required this.ambient,
    required this.entry,
    required this.fadeOut,
    this.compact = false,
  });

  final double progress;
  final Animation<double> ambient;
  final Animation<double> entry;
  final Animation<double> fadeOut;
  final bool compact;

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
        // Compact = animação mais curta, mas marca completa (lockup + tagline).
        final lockupT =
            reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(
                  ((entry.value - (compact ? 0.0 : 0.10)) /
                          (compact ? 0.35 : 0.55))
                      .clamp(0.0, 1.0),
                );
        final iconOnlyT = (1 - lockupT).clamp(0.0, 1.0);
        final taglineT =
            reduceMotion
                ? 1.0
                : Curves.easeOut.transform(
                  ((entry.value - (compact ? 0.08 : 0.20)) /
                          (compact ? 0.35 : 0.45))
                      .clamp(0.0, 1.0),
                );

        return Opacity(
          opacity: fadeOut.value.clamp(0.0, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s5,
                  TokensStrip.s3,
                  TokensStrip.s5,
                  TokensStrip.s6,
                ),
                child: Column(
                  children: [
                    SizedBox(height: size.height * (compact ? 0.22 : 0.22)),
                    Opacity(
                      opacity: entryT,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          reduceMotion ? 0 : (1 - entryT) * (compact ? 8 : 12),
                        ),
                        child: _SplashHeroMark(
                          phase: phase,
                          entry: entry.value,
                          reduceMotion: reduceMotion,
                          iconOnlyT: iconOnlyT,
                          lockupT: lockupT,
                          compact: compact,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? TokensStrip.s3 : TokensStrip.s4),
                    Opacity(
                      opacity: taglineT,
                      child: FocuxBrandTagline(
                        center: true,
                        fontSize: compact ? 12.5 : 14,
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity:
                          reduceMotion
                              ? 1
                              : Curves.easeOut.transform(
                                ((entry.value - 0.12) / 0.40).clamp(0.0, 1.0),
                              ),
                      child: _LoadingRail(progress: progress, primary: primary),
                    ),
                  ],
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
    required this.iconOnlyT,
    required this.lockupT,
    this.compact = false,
  });

  final double phase;
  final double entry;
  final bool reduceMotion;
  final double iconOnlyT;
  final double lockupT;
  final bool compact;

  static const _logoAspect = 925 / 1024;

  @override
  Widget build(BuildContext context) {
    final logoWidth = compact ? 156.0 : 184.0;
    final iconSize = compact ? 112.0 : 128.0;
    final floatY = reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 3;
    final scale =
        reduceMotion
            ? 1.0
            : 0.94 +
                Curves.easeOutCubic.transform(entry.clamp(0.0, 1.0)) * 0.06;

    return Transform.translate(
      offset: Offset(0, floatY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: SizedBox(
          width: logoWidth,
          height: logoWidth * _logoAspect + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: iconOnlyT,
                child: FocuxOfficialLogo.icon(size: iconSize),
              ),
              Opacity(
                opacity: lockupT,
                child: FocuxOfficialLogo.full(width: logoWidth),
              ),
            ],
          ),
        ),
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
              color: primary.withValues(alpha: 0.72),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.8,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, 280.0);
              final fillWidth = width * clamped;

              return SizedBox(
                width: width,
                height: 3.5,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: heroTealSurface(0.06),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (fillWidth > 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        width: fillWidth,
                        height: 3.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: primary,
                          boxShadow: TokensStrip.coloredDepthGlow(
                            primary,
                            strength: 0.22,
                          ),
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
