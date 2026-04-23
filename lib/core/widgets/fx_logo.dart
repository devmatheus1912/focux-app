import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Focux Personal — Brand Logo Component
///
/// Design System: Dark Premium / Glassmorphism
/// Consistente em todas as telas: login, onboarding, dashboard, etc.
///
/// [iconSize] — base size unit (default 56)
/// [showLabel] — horizontal lockup com wordmark + tagline
/// [light]     — true = white text (dark bg), false = dark text (light bg)
class FxLogo extends StatelessWidget {
  final double iconSize;
  final bool showLabel;
  final bool horizontal;
  final bool light;

  const FxLogo({
    super.key,
    this.iconSize = 56,
    this.showLabel = true,
    this.horizontal = true,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // F Icon with subtle brand glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6BFF).withValues(alpha: 0.18),
                  blurRadius: iconSize * 0.4,
                  spreadRadius: iconSize * 0.04,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => RadialGradient(
                center: Alignment.center,
                radius: 0.70,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.88, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/logo_icon.png',
                height: iconSize * 1.3,
                width: iconSize * 1.3,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              ),
            ),
          ),
          SizedBox(width: iconSize * 0.16),
          // Wordmark + Tagline
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'FOCUX ',
                        style: GoogleFonts.inter(
                          fontSize: iconSize * 0.36,
                          fontWeight: FontWeight.w800,
                          color: light
                              ? const Color(0xFFF0F4FF)
                              : const Color(0xFF0A0F1E),
                          letterSpacing: 2.0,
                        ),
                      ),
                      TextSpan(
                        text: 'PERSONAL',
                        style: GoogleFonts.inter(
                          fontSize: iconSize * 0.36,
                          fontWeight: FontWeight.w300,
                          color: light
                              ? const Color(0xFFF0F4FF).withValues(alpha: 0.80)
                              : const Color(0xFF0A0F1E).withValues(alpha: 0.65),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: iconSize * 0.04),
                Text(
                  'Treine com dados. Evolua com inteligência.',
                  style: GoogleFonts.inter(
                    fontSize: iconSize * 0.16,
                    fontWeight: FontWeight.w400,
                    color: light
                        ? const Color(0xFF8899B4)
                        : const Color(0xFF64748B),
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Icon-only variant
    return ShaderMask(
      shaderCallback: (bounds) => RadialGradient(
        center: Alignment.center,
        radius: 0.70,
        colors: [
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.88, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        'assets/images/logo_icon.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      ),
    );
  }
}

/// Shorthand — icon only, for AppBars, avatars, etc.
class FxLogoIcon extends StatelessWidget {
  final double size;
  const FxLogoIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => FxLogo(iconSize: size, showLabel: false);
}
