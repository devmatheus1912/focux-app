import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../utils/dashboard_shortcut_navigation.dart';
import 'dashboard_tool_grid.dart';
import 'dashboard_tools_catalog_sheet.dart';

export 'dashboard_tool_grid.dart';
export 'dashboard_tools_catalog_sheet.dart';

class DashboardCollapsibleToolsSection extends ConsumerWidget {
  const DashboardCollapsibleToolsSection({
    super.key,
    required this.isDark,
    required this.shortcutAspectRatio,
    this.hideFeaturedTools = false,
  });

  final bool isDark;
  final double shortcutAspectRatio;
  /// Modo foco: só header que abre o catálogo (sem grid featured).
  final bool hideFeaturedTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final mute = dashboardReadableMuted(context, isDark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final features = effectivePlanoFeatures(ref);
    final totalTools = DashboardToolShortcut.moreTools.length;
    final lockedCount = countLockedShortcuts(
      DashboardToolShortcut.moreTools,
      features,
    );
    final featuredShortcuts = DashboardToolShortcut.featuredTools;
    final featuredCount = featuredShortcuts.length;
    final hideFeatured = hideFeaturedTools;
    final collapsedHint =
        hideFeatured
            ? (lockedCount > 0
                ? '$totalTools no catálogo · $lockedCount no upgrade'
                : '$totalTools atalhos · toque para abrir')
            : lockedCount > 0
            ? '$featuredCount em destaque · $lockedCount no upgrade'
            : '$featuredCount em destaque · $totalTools no catálogo';

    void openCatalog() {
      dashboardHapticCollapseToggle();
      showDashboardToolsCatalogSheet(
        context,
        ref: ref,
        isDark: isDark,
        shortcutAspectRatio: shortcutAspectRatio,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              label:
                  '${DashboardMicrocopy.maisFerramentas}. $collapsedHint. '
                  '${DashboardMicrocopy.abrirCatalogo}',
              child: InkWell(
                onTap: openCatalog,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: fxStripCardDecoration(
                    context,
                    radius: TokensStrip.rCard,
                    glowStrength: 0.08,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DashboardMicrocopy.maisFerramentas,
                              style: FocuxHubTypography.sectionTitle(
                                context,
                                color: heading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              collapsedHint,
                              style: FocuxHubTypography.bodyMuted(
                                color: mute,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: link,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!hideFeatured)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardShortcutGrid(
                    shortcuts: featuredShortcuts,
                    isDark: isDark,
                    aspectRatio: shortcutAspectRatio,
                    onShortcut:
                        (shortcut) =>
                            openDashboardShortcut(context, ref, shortcut),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: Semantics(
                        button: true,
                        label: DashboardMicrocopy.verCatalogoCompleto,
                        child: InkWell(
                          onTap: openCatalog,
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rInput,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DashboardMicrocopy.verCatalogoCompleto,
                                  style: FocuxHubTypography.chip(link),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: link,
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
            ),
        ],
      ),
    );
  }
}
