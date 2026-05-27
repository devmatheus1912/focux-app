import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_provider.dart';
import 'brand_glass_mark.dart';

/// Logo/wordmark que respeita white-label do aluno (Enterprise).
class BrandedAppIdentity extends ConsumerWidget {
  const BrandedAppIdentity({
    super.key,
    this.size = 40,
    this.showLabel = true,
    this.light = true,
  });

  final double size;
  final bool showLabel;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideFocux = ref.watch(hideFocuxBrandingProvider);
    final appName = ref.watch(appDisplayNameProvider);
    final personalName = ref.watch(personalNameProvider);
    final logoUrl = ref.watch(logoUrlProvider);
    final primary = Theme.of(context).colorScheme.primary;

    final displayName = (appName != null && appName.trim().isNotEmpty)
        ? appName.trim()
        : (personalName != null && personalName.trim().isNotEmpty)
            ? personalName.trim()
            : 'Meu Personal';

    final mark = BrandGlassMark(
      size: size,
      logoUrl: logoUrl,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
      glowColor: light ? primary : null,
      shimmerAlpha: light ? 0.34 : null,
    );

    if (!showLabel) return mark;

    if (hideFocux) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.28),
          Flexible(
            child: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w700,
                color: light ? Colors.white : EagleTokens.ink,
                height: 1.1,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.30),
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
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.w700,
                      color: light ? Colors.white : EagleTokens.ink,
                      letterSpacing: -0.2,
                      height: 1,
                    ),
                  ),
                  WidgetSpan(child: SizedBox(width: size * 0.14)),
                  TextSpan(
                    text: 'PERSONAL',
                    style: AppTypography.inter(
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.w400,
                      color: light
                          ? Colors.white.withValues(alpha: 0.60)
                          : EagleTokens.ink.withValues(alpha: 0.50),
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

class BrandedAppIcon extends ConsumerWidget {
  const BrandedAppIcon({super.key, this.size = 40, this.light = true});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return BrandGlassMark(
      size: size,
      logoUrl: logoUrl,
      tone: light ? BrandGlassTone.dark : BrandGlassTone.light,
      glowColor: light ? primary : null,
      shimmerAlpha: light ? 0.34 : null,
    );
  }
}
