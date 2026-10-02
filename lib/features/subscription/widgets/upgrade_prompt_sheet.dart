import 'package:flutter/material.dart';

import '../../../core/api/api_error.dart';
import '../../../core/api/plan_upgrade_error_hub.dart';
import '../../../core/utils/friendly_error.dart';
import '../models/subscription_plan.dart';
import '../plan_entitlements.dart';
import '../services/upgrade_prompt_cooldown.dart';
import 'fx_upgrade_sales_sheet.dart';

/// Bottom sheet contextual de upgrade — venda canônica + CTA para `/assinatura`.
class UpgradePromptSheet {
  UpgradePromptSheet._();

  /// Tap explícito (atalho trancado) — sempre mostra, sem cooldown.
  static Future<void> show({
    required BuildContext context,
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
    SubscriptionPlan? upgradePlano,
    String source = 'upgrade_prompt',
  }) => FxUpgradeSalesSheet.show(
    context: context,
    featureName: featureName,
    capability: capability,
    requiredPlan: requiredPlan,
    upgradePlano: upgradePlano,
    source: source,
    respectCooldown: false,
  );

  /// Liga o [PlanUpgradeErrorHub]: erro de plano em qualquer chamada vira
  /// sheet de upgrade (só para personal — aluno nunca vê paywall).
  static void registerGlobalPresenter({
    required bool Function() isPersonal,
    required BuildContext? Function() rootContext,
  }) {
    PlanUpgradeErrorHub.presenter = (context, error) async {
      if (!isPersonal()) return false;
      final target = context ?? rootContext();
      if (target == null || !target.mounted) return false;
      return showFromError(target, error, source: 'api_error_global');
    };
  }

  /// Abre a sheet a partir de um erro de entitlement do contrato.
  static Future<bool> showFromError(
    BuildContext context,
    Object error, {
    String? fallbackFeatureName,
    String? fallbackCapability,
    String source = 'api_error',
  }) async {
    if (!isPlanGateError(error) && !PlanUpgradeErrorHub.isUpgradeError(error)) {
      return false;
    }
    final api = ApiError.from(error);
    final limiteAlunos = api?.codigo == PlanUpgradeErrorHub.limiteAlunos;
    final feature = api?.feature;
    final capability =
        limiteAlunos
            ? 'alunos'
            : PlanEntitlements.capabilityFromBackendFeature(feature) ??
                fallbackCapability;
    final featureName =
        limiteAlunos
            ? (fallbackFeatureName ?? 'Mais vagas de alunos')
            : fallbackFeatureName ??
                PlanEntitlements.featureNameFromBackendFeature(
                  feature,
                  fallback: 'recurso',
                );
    final upgradePlano =
        api?.upgradePlano != null && api!.upgradePlano!.trim().isNotEmpty
            ? subscriptionPlanFromApi(api.upgradePlano)
            : null;
    if (!context.mounted) return false;
    return PlanUpgradeErrorHub.run(
      () => show(
        context: context,
        featureName: featureName,
        capability: capability,
        upgradePlano: upgradePlano,
        source: source,
      ),
    );
  }

  static Future<void> showIfAllowed({
    required BuildContext context,
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
    SubscriptionPlan? upgradePlano,
  }) async {
    final triggerKey = UpgradePromptCooldown.keyFor(
      capability: capability,
      featureName: featureName,
    );
    if (!await UpgradePromptCooldown.shouldShow(triggerKey)) return;
    if (!context.mounted) return;

    await FxUpgradeSalesSheet.show(
      context: context,
      featureName: featureName,
      capability: capability,
      requiredPlan: requiredPlan,
      upgradePlano: upgradePlano,
      source: 'upgrade_prompt',
      respectCooldown: true,
      triggerKey: triggerKey,
    );
  }
}
