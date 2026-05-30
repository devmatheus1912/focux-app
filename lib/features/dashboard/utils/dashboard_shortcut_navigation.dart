import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/dashboard_tool_shortcuts.dart';

/// Navega para o atalho ou abre upgrade contextual (tap explícito = sem cooldown).
Future<void> openDashboardShortcut(
  BuildContext context,
  WidgetRef ref,
  DashboardToolShortcut shortcut,
) async {
  final features = ref.read(planoFeaturesProvider).valueOrNull ??
      PlanoFeatures.optimisticEnterprise;

  if (!shortcut.isUnlocked(features)) {
    AnalyticsService.instance.track(
      'dashboard_shortcut_locked_tap',
      props: {
        'label': shortcut.label,
        'capability': shortcut.capability,
        'target_plan': shortcut.targetPlan().apiName,
        'current_plan': features.plano.apiName,
      },
    );
    await UpgradePromptSheet.show(
      context: context,
      featureName: shortcut.displayFeatureName,
      capability: shortcut.capability,
      requiredPlan: shortcut.targetPlan(),
      source: 'dashboard_shortcut',
    );
    return;
  }

  if (shortcut.landingEditor) {
    await openLandingEditorOrUpgrade(context, ref);
    return;
  }

  final route = shortcut.route;
  if (route == null || !context.mounted) return;

  AnalyticsService.instance.track(
    'dashboard_shortcut_open',
    props: {
      'label': shortcut.label,
      'route': route,
      'plan': features.plano.apiName,
    },
  );
  context.push(route);
}

int countLockedShortcuts(
  List<DashboardToolShortcut> shortcuts,
  PlanoFeatures features,
) =>
    shortcuts.where((s) => !s.isUnlocked(features)).length;
