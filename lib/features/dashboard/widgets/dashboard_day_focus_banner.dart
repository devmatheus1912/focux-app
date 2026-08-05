import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_readability.dart';

class DashboardDayFocusBanner extends StatelessWidget {
  const DashboardDayFocusBanner({
    super.key,
    required this.focus,
    required this.isDark,
    required this.primary,
  });

  final DashboardDayFocus focus;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final accent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableMuted(context, isDark: isDark);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);

    return Semantics(
      container: true,
      label: focus.semanticLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          0,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1 : 0.96, end: 1),
          duration: dashboardMotionDuration(
            context,
            normal: const Duration(milliseconds: 320),
          ),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Opacity(
              opacity: reduceMotion ? 1 : (0.55 + (0.45 * ((scale - 0.96) / 0.04).clamp(0.0, 1.0))),
              child: Transform.scale(scale: scale, alignment: Alignment.topCenter, child: child),
            );
          },
          child: DecoratedBox(
          decoration: fxStripCardDecoration(
            context,
            accent: primary,
            radius: TokensStrip.rCard,
            glowStrength: 0.12,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: FxIcon(name: 'route', size: 18, color: accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foco do dia',
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        focus.headline,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        focus.detail,
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: mute,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
