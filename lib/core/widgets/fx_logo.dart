import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_provider.dart';

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
    final mark = _BrandedMarkTile(size: iconSize, logoUrl: logoUrl);

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
  const _BrandedMarkTile({required this.size, this.logoUrl});

  final double size;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF0D2830), Color(0xFF080C10)],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: EagleTokens.glassBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(size, radius),
    );
  }

  Widget _buildContent(double size, double radius) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _buildAssetLogo(size),
        ),
      );
    }
    return _buildAssetLogo(size);
  }

  Widget _buildAssetLogo(double size) {
    return OverflowBox(
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
    );
  }
}

/// Shorthand — tile only, for AppBars, list items, etc.
class FxLogoIcon extends ConsumerWidget {
  final double size;
  const FxLogoIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    return _BrandedMarkTile(size: size, logoUrl: logoUrl);
  }
}
