import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/command_action_item.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_readability.dart';

Color commandToneAccent(CommandActionTone tone, Color primary) {
  return switch (tone) {
    CommandActionTone.hot => Color.lerp(EagleTokens.warn, primary, 0.34)!,
    CommandActionTone.money => EagleTokens.moneyGreen,
    CommandActionTone.primary => primary,
  };
}

class CommandActionTile extends StatelessWidget {
  final CommandActionItem item;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;
  /// Stagger de entrada (0 = P0 hero leve).
  final int entranceIndex;

  const CommandActionTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.primary,
    this.onTap,
    this.entranceIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final accent = commandToneAccent(item.tone, primary);
    final badge = item.priorityBadge;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final isLead = entranceIndex == 0 &&
        (badge?.toUpperCase() == 'P0' ||
            item.tone == CommandActionTone.hot ||
            item.isRadarStudent);

    Widget tile = Semantics(
      label: '${item.title}. ${item.subtitle}',
      button: true,
      child: InkWell(
        onTap:
            onTap ??
            () {
              AnalyticsService.instance.track(
                ProductEvents.homeDayFocusAction,
                props: {
                  'route': item.route,
                  'title': item.title,
                  'priority': item.priorityBadge,
                  'source': 'next_actions',
                },
              );
              context.go(item.route);
            },
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: fxStripCardDecoration(
            context,
            accent: accent,
            radius: FxSettingsLayout.groupRadius,
            glowStrength: isLead ? (isDark ? 0.18 : 0.24) : 0.05,
            emphasize: isLead,
          ),
          child: Row(
            children: [
              FxIcon(
                name: item.icon,
                color: accent,
                size: FxSettingsLayout.iconSize,
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardCardTitleStyle(ink).copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: isLead ? -0.15 : -0.1,
                            ),
                          ),
                        ),
                        if (badge != null && badge.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Builder(
                            builder: (context) {
                              final badgeColors = dashboardPriorityBadgeColors(
                                isDark: isDark,
                                accent: accent,
                                badge: badge,
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      isDark
                                          ? Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          )
                                          : null,
                                ),
                                child: Text(
                                  badge,
                                  style: dashboardChipLabelStyle(
                                    badgeColors.foreground,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: isLead ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardCardSubtitleStyle(
                        context,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FxIcon(
                name: 'chevron-right',
                color: mute,
                size: FxSettingsLayout.chevronSize,
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion || !isLead) return tile;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: dashboardMotionDuration(
        context,
        normal: const Duration(milliseconds: 380),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        final t = ((scale - 0.94) / 0.06).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.55 + (0.45 * t),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: tile,
    );
  }
}
