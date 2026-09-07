import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../ferramentas/utils/ferramentas_catalogo_nav.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/dashboard_tool_shortcuts.dart';
import 'dashboard_tool_recent_store.dart';

/// Navega para o atalho ou abre upgrade contextual (tap explícito = sem cooldown).
Future<void> openDashboardShortcut(
  BuildContext context,
  WidgetRef ref,
  DashboardToolShortcut shortcut, {
  PlanoFeatures? homeOverride,
}) async {
  final features = effectivePlanoFeatures(ref, homeOverride: homeOverride);

  if (!shortcut.isUnlocked(features)) {
    AnalyticsService.instance.track(
      'dashboard_shortcut_locked_tap',
      props: {
        'label': shortcut.label,
        'capability': shortcut.capability,
        'target_plan': shortcut.targetPlan().apiName,
        'current_plan': features.plano.apiName,
        'legacy_ids': shortcut.entrada.legacyIds.join(','),
      },
    );
    await UpgradePromptSheet.show(
      context: context,
      featureName: shortcut.displayFeatureName,
      capability: shortcut.capability,
      requiredPlan: shortcut.targetPlan(),
      upgradePlano: shortcut.targetPlan(),
      source: 'dashboard_shortcut',
    );
    return;
  }

  final route = shortcut.route;
  if (route != null && route.isNotEmpty) {
    await DashboardToolRecentStore.recordRoute(route);
  }

  if (!context.mounted) return;
  await openCatalogoEntrada(
    context,
    ref,
    shortcut.entrada,
    preferredAbaId: shortcut.preferredAbaId,
    source: 'dashboard_shortcut',
  );
}

int countLockedShortcuts(
  List<DashboardToolShortcut> shortcuts,
  PlanoFeatures features,
) => shortcuts.where((s) => !s.isUnlocked(features)).length;
