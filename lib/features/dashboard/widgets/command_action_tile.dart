import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../data/command_action_item.dart';
import '../utils/dashboard_readability.dart';
import '../utils/open_dashboard_command_action.dart';

Color commandToneAccent(CommandActionTone tone, Color primary) {
  return switch (tone) {
    CommandActionTone.hot => Color.lerp(EagleTokens.warn, primary, 0.34)!,
    CommandActionTone.money => EagleTokens.moneyGreen,
    CommandActionTone.primary => primary,
  };
}

/// Linha inset (ChatGPT/iOS) — ícone 22, chevron 17, divisor após o ícone.
class CommandActionTile extends ConsumerWidget {
  final CommandActionItem item;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;
  final bool showDivider;

  const CommandActionTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.primary,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final accent = commandToneAccent(item.tone, primary);
    final badge = item.priorityBadge;

    return Semantics(
      label: '${item.title}. ${item.subtitle}',
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) {
            onTap!();
            return;
          }
          openDashboardCommandAction(
            context: context,
            ref: ref,
            item: item,
            source: 'next_actions',
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border:
                        showDivider
                            ? Border(
                              bottom: BorderSide(
                                color: chrome.line,
                                width: FxSettingsLayout.dividerThickness,
                              ),
                            )
                            : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
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
                                      style: FocuxHubTypography.cardTitle(
                                        color: chrome.ink,
                                      ),
                                    ),
                                  ),
                                  if (badge != null && badge.isNotEmpty) ...[
                                    const SizedBox(width: TokensStrip.s1),
                                    Builder(
                                      builder: (context) {
                                        final badgeColors =
                                            dashboardPriorityBadgeColors(
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
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border:
                                                isDark
                                                    ? Border.all(
                                                      color: Colors.white
                                                          .withValues(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.bodyMuted(
                                  color: mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: FxSettingsLayout.chevronSize,
                          color: mute,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
