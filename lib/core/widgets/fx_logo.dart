import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'brand_glass_mark.dart';

/// Focux Personal — Brand Logo Component
///
/// Uses the official transparent logo mark across in-app chrome.
/// White-label [logoUrl] overrides apply on student/public surfaces only.
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
    final primary = Theme.of(context).colorScheme.primary;
    final mark = _BrandedMarkTile(
      size: iconSize,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
      glowColor: light ? primary : null,
      shimmerAlpha: light ? 0.38 : null,
    );

    if (!showLabel) return mark;

    final wordmarkColor = light ? Colors.white : EagleTokens.ink;
    final muteColor =
        light
            ? Colors.white.withValues(alpha: 0.60)
            : EagleTokens.ink.withValues(alpha: 0.50);

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
                    style: AppTypography.inter(
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
                    style: AppTypography.inter(
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

/// BrandedMark — Focux platform glass tile with default F asset.
class _BrandedMarkTile extends StatelessWidget {
  const _BrandedMarkTile({
    required this.size,
    required this.tone,
    this.glowColor,
    this.shimmerAlpha,
  });

  final double size;
  final BrandGlassTone tone;
  final Color? glowColor;
  final double? shimmerAlpha;

  @override
  Widget build(BuildContext context) {
    return BrandGlassMark(
      size: size,
      tone: tone,
      glowColor: glowColor,
      shimmerAlpha: shimmerAlpha,
    );
  }
}

/// Shorthand — tile only, for AppBars, list items, etc.
class FxLogoIcon extends StatelessWidget {
  final double size;
  final bool light;

  const FxLogoIcon({super.key, this.size = 40, this.light = true});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _BrandedMarkTile(
      size: size,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
      glowColor: light ? primary : null,
      shimmerAlpha: light ? 0.34 : null,
    );
  }
}
