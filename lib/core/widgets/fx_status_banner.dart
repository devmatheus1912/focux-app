import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';
import 'fx_shell_scaffold.dart';

enum FxBannerTone { info, warn, success }

/// Banner de status: título + texto num fundo tingido pelo tom.
class FxStatusBanner extends StatelessWidget {
  const FxStatusBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = FxBannerTone.info,
  });

  final String title;
  final String body;
  final FxBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final Color accent = switch (tone) {
      FxBannerTone.warn => EagleTokens.warn,
      FxBannerTone.success => EagleTokens.good,
      FxBannerTone.info => BrandPalette.sectionAccent(primary, dark: isDark),
    };
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Semantics(
      container: true,
      label: '$title. $body',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FxIcon(
                name: tone == FxBannerTone.warn
                    ? 'alert-triangle'
                    : tone == FxBannerTone.success
                    ? 'circle-check'
                    : 'bell',
                size: 22,
                color: accent,
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FocuxHubTypography.cardTitle(color: ink),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      body,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
