import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Focux Personal — Brand Logo Component
///
/// Design System: Dark Premium / Eagle Tokens
/// FxMark = rounded-square tile, dark blue radial gradient, F-eagle image
/// Consistent across all screens: login, onboarding, dashboard, etc.
///
/// [iconSize] — tile size in pixels (default 40)
/// [showLabel] — horizontal lockup: tile + wordmark
/// [light]     — true = white wordmark text (dark bg), false = dark text (light bg)
class FxLogo extends StatelessWidget {
  final double iconSize;
  final bool showLabel;
  final bool horizontal;
  final bool light;

  const FxLogo({
    super.key,
    this.iconSize = 40,
    this.showLabel = true,
    this.horizontal = true,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    final mark = _FxMarkTile(size: iconSize);

    if (!showLabel) return mark;

    final wordmarkColor = light ? Colors.white : const Color(0xFF0D0F14);
    final muteColor =
        light
            ? Colors.white.withValues(alpha: 0.60)
            : const Color(0xFF0D0F14).withValues(alpha: 0.50);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: iconSize * 0.30),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'FOCUX',
                    style: GoogleFonts.outfit(
                      fontSize: iconSize * 0.55,
                      fontWeight: FontWeight.w700,
                      color: wordmarkColor,
                      letterSpacing: -0.2,
                      height: 1,
                    ),
                  ),
                  WidgetSpan(child: SizedBox(width: iconSize * 0.14)),
                  TextSpan(
                    text: 'PERSONAL',
                    style: GoogleFonts.outfit(
                      fontSize: iconSize * 0.55,
                      fontWeight: FontWeight.w400,
                      color: muteColor,
                      letterSpacing: 0.3,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rounded-square brand tile — matches design FxMark "official" variant.
///
/// Dark blue radial gradient background + F-eagle image.
/// Inset border + drop shadow matching design spec.
class _FxMarkTile extends StatelessWidget {
  const _FxMarkTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF122E65), Color(0xFF050B20)],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3454D1).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color.fromRGBO(124, 192, 255, 0.12),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // ShaderMask with BlendMode.screen simulates CSS mix-blend-mode:screen —
      // mathematically equivalent (screen is commutative). The gradient shader
      // matches the tile background so eagle pixels are brightened/luminous.
      child: ShaderMask(
        shaderCallback:
            (Rect bounds) => const RadialGradient(
              center: Alignment(-0.3, -0.5),
              radius: 1.0,
              colors: [Color(0xFF122E65), Color(0xFF050B20)],
              stops: [0.0, 1.0],
            ).createShader(bounds),
        blendMode: BlendMode.screen,
        child: OverflowBox(
          maxWidth: size * 1.3,
          maxHeight: size * 1.3,
          child: Image.asset(
            'assets/images/logo_icon.png',
            width: size * 1.3,
            height: size * 1.3,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
      ),
    );
  }
}

/// Shorthand — tile only, for AppBars, list items, etc.
class FxLogoIcon extends StatelessWidget {
  final double size;
  const FxLogoIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => _FxMarkTile(size: size);
}
