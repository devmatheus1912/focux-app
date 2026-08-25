import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../data/command_action_item.dart';
import '../utils/dashboard_microcopy.dart';
import 'command_action_tile.dart';
import 'command_status_tile.dart';

class CommandActionPanel extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool loading;
  final bool unavailable;
  final List<CommandActionItem> actions;
  final String? prioritiesActionLabel;
  final VoidCallback? onPrioritiesTap;

  const CommandActionPanel({
    super.key,
    required this.isDark,
    required this.primary,
    required this.loading,
    this.unavailable = false,
    required this.actions,
    this.prioritiesActionLabel,
    this.onPrioritiesTap,
  });

  @override
  Widget build(BuildContext context) {
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DashboardMicrocopy.proximasAcoes,
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: heading,
                ),
              ),
            ),
            if (prioritiesActionLabel != null && onPrioritiesTap != null)
              Semantics(
                button: true,
                label: prioritiesActionLabel,
                child: TextButton(
                  onPressed: loading ? null : onPrioritiesTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: link,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    prioritiesActionLabel!,
                    style: FocuxHubTypography.chip(link)
                        .copyWith(letterSpacing: 0.2),
                  ),
                ),
              )
            else
              Text(
                DashboardMicrocopy.impactoHoje,
                style: FocuxHubTypography.chip(link)
                    .copyWith(letterSpacing: 0.2),
              ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.headerToGroup),
        FxSettingsGroup(
          accent: primary,
          children: [
            if (loading)
              CommandActionsShimmer(isDark: isDark, primary: primary)
            else if (unavailable)
              CommandStatusTile(
                isDark: isDark,
                primary: primary,
                icon: Icons.cloud_off_rounded,
                title: 'Central temporariamente indisponível',
                subtitle: 'Puxe para atualizar ou tente em instantes.',
              )
            else if (actions.isEmpty)
              CommandStatusTile(
                isDark: isDark,
                primary: primary,
                icon: Icons.check_circle_outline_rounded,
                title: 'Operação sob controle',
                subtitle: 'Nenhuma ação crítica para agora.',
              )
            else
              for (var index = 0; index < actions.length; index++)
                CommandActionTile(
                  item: actions[index],
                  isDark: isDark,
                  primary: primary,
                  showDivider: index < actions.length - 1,
                ),
          ],
        ),
      ],
    );
  }
}

class CommandActionsShimmer extends StatelessWidget {
  const CommandActionsShimmer({
    super.key,
    required this.isDark,
    required this.primary,
  });

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == 0 ? TokensStrip.s2 : 0),
          child: Shimmer.fromColors(
            baseColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            child: Container(
              height: FxSettingsLayout.rowMinHeight,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(
                  FxSettingsLayout.groupRadius,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
