import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/ferramentas_catalogo_models.dart';
import 'ferramentas_gates.dart';
import 'ferramentas_icons.dart';

export 'ferramentas_gates.dart';

/// Abre folha, hub com abas, ou paywall conforme `unlocked` / featureGate.
Future<void> openCatalogoEntrada(
  BuildContext context,
  WidgetRef ref,
  CatalogoEntrada entrada, {
  String? preferredAbaId,
  String source = 'catalogo',
}) async {
  final capability = capabilityFromEntrada(entrada);
  final planLocked =
      !entrada.isHubComAbas &&
      capability != null &&
      PlanoRecursoKeys.fromCapability(capability) != null &&
      !PlanGate.read(ref, capability).liberado;

  if (!entrada.unlocked || planLocked) {
    AnalyticsService.instance.track(
      'dashboard_shortcut_locked_tap',
      props: {
        'label': entrada.titulo,
        'capability': capability,
        'target_plan': upgradePlanFromEntrada(entrada).apiName,
        'legacy_ids': entrada.legacyIds.join(','),
        'source': source,
      },
    );
    await UpgradePromptSheet.show(
      context: context,
      featureName: entrada.titulo,
      capability: capability,
      requiredPlan: upgradePlanFromEntrada(entrada),
      upgradePlano: upgradePlanFromEntrada(entrada),
      source: source,
    );
    return;
  }

  if (entrada.isHubComAbas) {
    AnalyticsService.instance.track(
      'dashboard_shortcut_open',
      props: {
        'label': entrada.titulo,
        'route': ferramentasHubLocation(entrada.id, abaId: preferredAbaId),
        'source': source,
      },
    );
    if (!context.mounted) return;
    context.push(
      ferramentasHubLocation(entrada.id, abaId: preferredAbaId),
    );
    return;
  }

  final route = normalizeFerramentasRotaApp(entrada.rotaApp);
  if (route == '/perfil/landing-editor') {
    await openLandingEditorOrUpgrade(context, ref);
    return;
  }
  if (route == null || !context.mounted) return;

  AnalyticsService.instance.track(
    'dashboard_shortcut_open',
    props: {
      'label': entrada.titulo,
      'route': route,
      'legacy_ids': entrada.legacyIds.join(','),
      'source': source,
    },
  );
  context.push(route);
}
