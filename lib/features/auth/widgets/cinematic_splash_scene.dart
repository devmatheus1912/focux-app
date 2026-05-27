import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';
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
        final lockupT =
            compact
                ? 0.0
                : reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(
                  ((entry.value - 0.10) / 0.55).clamp(0.0, 1.0),
                );
        final iconOnlyT = compact ? 1.0 : (1 - lockupT).clamp(0.0, 1.0);

        return Opacity(
          opacity: fadeOut.value.clamp(0.0, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * (compact ? 0.26 : 0.22)),
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
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 18),
                        Opacity(
                          opacity:
                              reduceMotion
                                  ? 1
                                  : Curves.easeOut.transform(
                                    ((entry.value - 0.20) / 0.45).clamp(0.0, 1.0),
                                  ),
                          child: const FocuxBrandTagline(center: true, fontSize: 14),
                        ),
                      ],
                      const Spacer(),
                      Opacity(
                        opacity:
                            reduceMotion
                                ? 1
                                : Curves.easeOut.transform(
                                  ((entry.value - 0.12) / 0.40).clamp(0.0, 1.0),
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
    required this.iconOnlyT,
    required this.lockupT,
  });

  final double phase;
  final double entry;
  final bool reduceMotion;
  final double iconOnlyT;
  final double lockupT;

  static const _logoWidth = 184.0;
  static const _logoAspect = 925 / 1024;
  static const _nativeIconSize = 128.0;

  @override
  Widget build(BuildContext context) {
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
          width: _logoWidth,
          height: _logoWidth * _logoAspect + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: iconOnlyT,
                child: FocuxOfficialLogo.icon(size: _nativeIconSize),
              ),
              Opacity(
                opacity: lockupT,
                child: FocuxOfficialLogo.full(width: _logoWidth),
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
