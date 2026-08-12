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
        focusMode ? DashboardMicrocopy.modoFocoChipOn : DashboardMicrocopy.modoFocoChipOff;

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
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.45,
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
                          message: DashboardMicrocopy.modoFoco,
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
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      focusMode
                                          ? BrandPalette.soft(
                                            primary,
                                            dark: isDark,
                                          ).withValues(
                                            alpha: isDark ? 0.62 : 0.95,
                                          )
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    width: focusMode ? 1.4 : 1,
                                    color:
                                        focusMode
                                            ? primary.withValues(alpha: 0.65)
                                            : accent.withValues(alpha: 0.42),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      focusMode
                                          ? Icons.bolt_rounded
                                          : Icons.bolt_outlined,
                                      size: 15,
                                      color: link,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      chipLabel,
                                      style: AppTypography.inter(
                                        fontSize: TokensStrip.fontBodySm,
                                        fontWeight: FontWeight.w800,
                                        color: link,
                                        letterSpacing: 0.12,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    focus.headline,
                    style: AppTypography.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      height: 1.18,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    focus.detail,
                    style: dashboardCardSubtitleStyle(
                      context,
                      isDark: isDark,
                    ).copyWith(height: 1.35),
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
