import 'package:flutter/material.dart';

import '../../../core/api/api_error.dart';
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

  /// Abre a sheet a partir de um erro de entitlement do contrato.
  static Future<bool> showFromError(
    BuildContext context,
    Object error, {
    String? fallbackFeatureName,
    String? fallbackCapability,
    String source = 'api_error',
  }) async {
    if (!isPlanGateError(error)) return false;
    final api = ApiError.from(error);
    final feature = api?.feature;
    final capability =
        PlanEntitlements.capabilityFromBackendFeature(feature) ??
        fallbackCapability;
    final featureName =
        fallbackFeatureName ??
        PlanEntitlements.featureNameFromBackendFeature(
          feature,
          fallback: 'recurso',
        );
    final upgradePlano =
        api?.upgradePlano != null && api!.upgradePlano!.trim().isNotEmpty
            ? subscriptionPlanFromApi(api.upgradePlano)
            : null;
    if (!context.mounted) return false;
    await show(
      context: context,
      featureName: featureName,
      capability: capability,
      upgradePlano: upgradePlano,
      source: source,
    );
    return true;
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
