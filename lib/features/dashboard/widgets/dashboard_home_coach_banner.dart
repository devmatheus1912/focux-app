import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_microcopy.dart';

/// Banner one-shot: aponta o catálogo de ferramentas.
class DashboardHomeCoachBanner extends StatelessWidget {
  const DashboardHomeCoachBanner({
    super.key,
    required this.isDark,
    required this.onDismiss,
  });

  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s2,
      ),
      child: Semantics(
        liveRegion: true,
        label: DashboardMicrocopy.coachCatalogHint,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                isDark
                    ? EagleTokens.darkCardHi
                    : BrandPalette.soft(primary, dark: false),
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DashboardMicrocopy.coachCatalogHint,
                    style: FocuxHubTypography.body(color: ink).copyWith(
                      height: 1.25,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    DashboardMicrocopy.coachEntendi,
                    style: FocuxHubTypography.chip(primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
