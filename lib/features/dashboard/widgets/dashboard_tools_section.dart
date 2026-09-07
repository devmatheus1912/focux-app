import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../ferramentas/providers/ferramentas_catalogo_provider.dart';
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
    this.onboardingCompleto = false,
  });

  final bool isDark;

  /// Modo foco: só a linha do catálogo (sem lista em destaque).
  final bool hideFeaturedTools;
  final PlanoFeatures? homePlanoFeatures;
  final bool onboardingCompleto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = effectivePlanoFeatures(
      ref,
      homeOverride: homePlanoFeatures,
    );
    final catalogoAsync = ref.watch(ferramentasCatalogoProvider);
    final primary = Theme.of(context).colorScheme.primary;

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
      ),
      child: catalogoAsync.when(
        loading:
            () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SkeletonList(count: 3),
            ),
        error:
            (e, _) => FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: 'Não deu para carregar o catálogo',
              onRetry: () => ref.invalidate(ferramentasCatalogoProvider),
            ),
        data: (catalogo) {
          final featuredShortcuts = atalhosHomeFromCatalogo(
            catalogo,
            hideOnboardingWizard: onboardingCompleto,
          );
          final leafCount = catalogo.hubs.fold<int>(
            0,
            (sum, h) => sum + h.itens.length,
          );
          final lockedCount = countLockedShortcuts(
            [
              for (final hub in catalogo.hubs)
                ...catalogLeavesFromHub(hub),
            ],
            features,
          );
          final featuredCount = featuredShortcuts.length;
          final hideFeatured = hideFeaturedTools;
          final caption =
              hideFeatured
                  ? (lockedCount > 0
                      ? '${catalogo.hubs.length} hubs · $lockedCount no upgrade'
                      : '${catalogo.hubs.length} hubs · toque para abrir')
                  : lockedCount > 0
                  ? '$featuredCount em destaque · $lockedCount no upgrade'
                  : '$featuredCount em destaque · $leafCount no catálogo';

          if (hideFeatured) {
            return CommandActionTile(
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
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardSectionHeader(
                title: DashboardMicrocopy.maisFerramentas,
                actionLabel: DashboardMicrocopy.verCatalogoCompleto,
                onAction: openCatalog,
              ),
              const SizedBox(height: FxSettingsLayout.headerToGroup),
              if (featuredShortcuts.isEmpty)
                CommandActionTile(
                  item: CommandActionItem(
                    icon: 'spark',
                    title: DashboardMicrocopy.verCatalogoCompleto,
                    subtitle: caption,
                    route: '',
                    tone: CommandActionTone.primary,
                  ),
                  isDark: isDark,
                  primary: primary,
                  showDivider: false,
                  onTap: openCatalog,
                )
              else
                for (var i = 0; i < featuredShortcuts.length; i++)
                  CommandActionTile(
                    item: CommandActionItem(
                      icon: featuredShortcuts[i].icon,
                      title: featuredShortcuts[i].label,
                      subtitle:
                          featuredShortcuts[i].isUnlocked(features)
                              ? (featuredShortcuts[i].entrada.subtitulo ?? '')
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
          );
        },
      ),
    );
  }
}
