import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

enum AnamneseBannerTone { info, warn, success }

/// Banner de status no fluxo do aluno (solicitar / atestado / enviada).
class AnamneseStatusBanner extends StatelessWidget {
  const AnamneseStatusBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = AnamneseBannerTone.info,
  });

  final String title;
  final String body;
  final AnamneseBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final Color accent = switch (tone) {
      AnamneseBannerTone.warn => EagleTokens.warn,
      AnamneseBannerTone.success => EagleTokens.good,
      AnamneseBannerTone.info => BrandPalette.sectionAccent(primary, dark: isDark),
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
                name: tone == AnamneseBannerTone.warn
                    ? 'alert-triangle'
                    : tone == AnamneseBannerTone.success
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
