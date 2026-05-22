import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/brand_glass_mark.dart';

/// Cinematic splash foreground — same mesh as login, glass F mark,
/// subtle motion, divider flare, loading rail.
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

    return AnimatedBuilder(
      animation: Listenable.merge([ambient, entry, fadeOut]),
      builder: (context, _) {
        final phase = ambient.value;
        final entryT = Curves.easeOutCubic.transform(entry.value.clamp(0.0, 1.0));

        return Opacity(
          opacity: fadeOut.value.clamp(0.0, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RadialTargetsPainter(
                  centerY: size.height * 0.34,
                  rotation: phase * math.pi * 2,
                  pulse: 0.5 + math.sin(phase * math.pi * 2) * 0.5,
                  primary: primary,
                ),
                size: Size.infinite,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.07),
                      Opacity(
                        opacity: entryT,
                        child: Transform.translate(
                          offset: Offset(0, (1 - entryT) * 28),
                          child: _SplashHeroMark(
                            phase: phase,
                            entry: entry.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          (entry.value - 0.12).clamp(0.0, 1.0),
                        ),
                        child: _PremiumSplashWordmark(
                          phase: phase,
                          primary: primary,
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          (entry.value - 0.28).clamp(0.0, 1.0),
                        ),
                        child: _PremiumLoadingRail(
                          progress: progress,
                          phase: phase,
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
  });

  final double phase;
  final double entry;

  @override
  Widget build(BuildContext context) {
    const markSize = 184.0;
    final spin = math.sin(phase * math.pi * 2) * 0.10;
    final scale =
        0.92 + Curves.elasticOut.transform(entry.clamp(0.0, 1.0)) * 0.08;

    return Transform(
      alignment: Alignment.center,
      transform:
          Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(spin)
            ..scale(scale),
      child: BrandGlassMark(
        size: markSize,
        shimmerAlpha: 0.08,
        enableBackdropBlur: false,
      ),
    );
  }
}

class _PremiumSplashWordmark extends StatelessWidget {
  const _PremiumSplashWordmark({
    required this.phase,
    required this.primary,
  });

  final double phase;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final flarePulse = 0.65 + math.sin(phase * math.pi * 2) * 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'FOCUX',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PERSONAL',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: primary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 5.0,
            height: 1,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 210,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primary.withValues(alpha: 0.20),
                      primary.withValues(alpha: 0.55 * flarePulse),
                      primary.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9 * flarePulse),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.65 * flarePulse),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Treine com dados. Evolua com inteligência.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.44),
            fontSize: 13,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _PremiumLoadingRail extends StatelessWidget {
  const _PremiumLoadingRail({
    required this.progress,
    required this.phase,
    required this.primary,
  });

  final double progress;
  final double phase;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final pulse = 0.7 + math.sin(phase * math.pi * 2) * 0.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CARREGANDO',
          style: GoogleFonts.outfit(
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
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  if (fillWidth > 2)
                    Positioned(
                      left: 0,
                      width: fillWidth,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.45),
                              primary,
                              EagleTokens.brandAccent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.50),
                              blurRadius: 12,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (fillWidth > 8)
                    Positioned(
                      left: fillWidth - 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              primary.withValues(alpha: 0.75 * pulse),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.70 * pulse),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RadialTargetsPainter extends CustomPainter {
  _RadialTargetsPainter({
    required this.centerY,
    required this.rotation,
    required this.pulse,
    required this.primary,
  });

  final double centerY;
  final double rotation;
  final double pulse;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, centerY);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 0.05);

    for (var i = 0; i < 5; i++) {
      final radius = 48.0 + i * 36.0;
      final alpha = (0.14 - i * 0.022) * (0.65 + pulse * 0.35);
      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.75
            ..color = EagleTokens.brandAccent.withValues(
              alpha: alpha.clamp(0.03, 0.16),
            );
      canvas.drawCircle(Offset.zero, radius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadialTargetsPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.centerY != centerY;
  }
}
