import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

class DashboardDayFocusBanner extends StatelessWidget {
  const DashboardDayFocusBanner({
    super.key,
    required this.focus,
    required this.isDark,
    required this.primary,
    required this.focusMode,
    required this.onToggleFocus,
  });

  final DashboardDayFocus focus;
  final bool isDark;
  final Color primary;
  final bool focusMode;
  final VoidCallback onToggleFocus;

  @override
  Widget build(BuildContext context) {
    final accent = BrandPalette.sectionAccent(primary, dark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final chipLabel =
        focusMode
            ? DashboardMicrocopy.modoFocoChipOn
            : DashboardMicrocopy.modoFocoChipOff;

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
              opacity:
                  reduceMotion
                      ? 1
                      : (0.55 +
                          (0.45 * ((scale - 0.96) / 0.04).clamp(0.0, 1.0))),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: fxStripCardDecoration(
              context,
              accent: primary,
              radius: TokensStrip.rCard,
              glowStrength: focusMode ? 0.10 : 0.05,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: isDark ? 0.24 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: FxIcon(
                            name: 'route',
                            size: 17,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Foco do dia',
                          style: dashboardMicroLabelStyle(
                            context,
                            isDark: isDark,
                            color: accent,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        toggled: focusMode,
                        label:
                            focusMode
                                ? DashboardMicrocopy.modoFocoOn
                                : DashboardMicrocopy.modoFocoOff,
                        child: Tooltip(
                          message:
                              focusMode
                                  ? DashboardMicrocopy.modoFocoChipOnHint
                                  : DashboardMicrocopy.modoFocoChipOffHint,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onToggleFocus,
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 36,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      focusMode
                                          ? primary
                                          : BrandPalette.soft(
                                            primary,
                                            dark: isDark,
                                          ).withValues(
                                            alpha: isDark ? 0.28 : 0.55,
                                          ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    width: focusMode ? 0 : 1.4,
                                    color: accent.withValues(alpha: 0.72),
                                  ),
                                  boxShadow:
                                      focusMode
                                          ? [
                                            BoxShadow(
                                              color: primary.withValues(
                                                alpha: isDark ? 0.45 : 0.28,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      focusMode
                                          ? Icons.bolt_rounded
                                          : Icons.bolt_outlined,
                                      size: 15,
                                      color:
                                          focusMode
                                              ? (isDark
                                                  ? EagleTokens.brandDeep
                                                  : Colors.white)
                                              : link,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      chipLabel,
                                      style: dashboardActionChipStyle(
                                        focusMode
                                            ? (isDark
                                                ? EagleTokens.brandDeep
                                                : Colors.white)
                                            : link,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (focusMode) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color:
                                            isDark
                                                ? EagleTokens.brandDeep
                                                : Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  Text(
                    focus.headline,
                    style: dashboardPageTitleStyle(context, color: ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    focus.detail,
                    style: dashboardCardSubtitleStyle(
                      context,
                      isDark: isDark,
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
