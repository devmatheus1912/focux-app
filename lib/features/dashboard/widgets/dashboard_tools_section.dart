import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/data/planos_repository.dart';
import '../data/command_action_item.dart';
import 'command_action_tile.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import 'dashboard_section_header.dart';
import 'dashboard_tools_catalog_sheet.dart';

export 'dashboard_tools_catalog_sheet.dart';

class DashboardHomeToolsSection extends ConsumerWidget {
  const DashboardHomeToolsSection({
    super.key,
    required this.isDark,
    this.hideFeaturedTools = false,
    this.homePlanoFeatures,
  });

  final bool isDark;
  /// Modo foco: só a linha do catálogo (sem lista em destaque).
  final bool hideFeaturedTools;
  final PlanoFeatures? homePlanoFeatures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(
      ref,
      homeOverride: homePlanoFeatures,
    );
    final totalTools = DashboardToolShortcut.moreTools.length;
    final lockedCount = countLockedShortcuts(
      DashboardToolShortcut.moreTools,
      features,
    );
    final featuredShortcuts = DashboardToolShortcut.featuredTools;
    final featuredCount = featuredShortcuts.length;
    final hideFeatured = hideFeaturedTools;
    final caption =
        hideFeatured
            ? (lockedCount > 0
                ? '$totalTools no catálogo · $lockedCount no upgrade'
                : '$totalTools atalhos · toque para abrir')
            : lockedCount > 0
            ? '$featuredCount em destaque · $lockedCount no upgrade'
            : '$featuredCount em destaque · $totalTools no catálogo';

    void openCatalog() {
      dashboardHapticCollapseToggle();
      AnalyticsService.instance.track(ProductEvents.homeCatalogOpened);
      showDashboardToolsCatalogSheet(
        context,
        ref: ref,
        isDark: isDark,
        homePlanoFeatures: homePlanoFeatures,
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hideFeatured)
            CommandActionTile(
              item: CommandActionItem(
                icon: 'spark',
                title: DashboardMicrocopy.maisFerramentas,
                subtitle: caption,
                route: '',
                tone: CommandActionTone.primary,
              ),
              isDark: isDark,
              primary: primary,
              showDivider: false,
              onTap: openCatalog,
            )
          else ...[
            DashboardSectionHeader(
              title: DashboardMicrocopy.maisFerramentas,
              actionLabel: DashboardMicrocopy.verCatalogoCompleto,
              onAction: openCatalog,
            ),
            const SizedBox(height: FxSettingsLayout.headerToGroup),
            for (var i = 0; i < featuredShortcuts.length; i++)
              CommandActionTile(
                item: CommandActionItem(
                  icon: featuredShortcuts[i].icon,
                  title: featuredShortcuts[i].label,
                  subtitle:
                      featuredShortcuts[i].isUnlocked(features)
                          ? ''
                          : 'Requer ${featuredShortcuts[i].tierBadgeLabel()}',
                  route: featuredShortcuts[i].route ?? '',
                  tone: CommandActionTone.primary,
                  priorityBadge:
                      featuredShortcuts[i].isUnlocked(features)
                          ? null
                          : featuredShortcuts[i].tierBadgeLabel(),
                ),
                isDark: isDark,
                primary: primary,
                showDivider: i < featuredShortcuts.length - 1,
                onTap:
                    () => openDashboardShortcut(
                      context,
                      ref,
                      featuredShortcuts[i],
                      homeOverride: homePlanoFeatures,
                    ),
              ),
          ],
        ],
      ),
    );
  }
}
