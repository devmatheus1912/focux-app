import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_provider.dart';
import 'brand_glass_mark.dart';

/// Focux Personal — Brand Logo Component (Cinematic Redesign)
///
/// Design System: Cyan-Teal Glass / Eagle Tokens
/// BrandedMark = uses logoUrlProvider when available, falls back to asset.
/// Consistent across all screens: login, onboarding, dashboard, etc.
///
/// [iconSize] — tile size in pixels (default 40)
/// [showLabel] — horizontal lockup: tile + wordmark
/// [light]     — true = white wordmark text (dark bg), false = dark text (light bg)
class FxLogo extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    final mark = _BrandedMarkTile(
      size: iconSize,
      logoUrl: logoUrl,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
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

/// BrandedMark — uses network logo when available, else asset.
///
/// Cinematic glass background: teal gradient + glass border + brand glow shadow.
/// When personal has a custom logoUrl, it displays their logo instead.
class _BrandedMarkTile extends StatelessWidget {
  const _BrandedMarkTile({
    required this.size,
    required this.tone,
    this.logoUrl,
  });

  final double size;
  final String? logoUrl;
  final BrandGlassTone tone;

  @override
  Widget build(BuildContext context) {
    final hasCustomLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return BrandGlassMark(
      size: size,
      logoUrl: hasCustomLogo ? logoUrl : null,
      tone: tone,
    );
  }
}

/// Shorthand — tile only, for AppBars, list items, etc.
class FxLogoIcon extends ConsumerWidget {
  final double size;
  final bool light;

  const FxLogoIcon({super.key, this.size = 40, this.light = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    return _BrandedMarkTile(
      size: size,
      logoUrl: logoUrl,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
    );
  }
}
