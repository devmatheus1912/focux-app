import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../models/subscription_plan.dart';
import '../plan_entitlements.dart';
import '../services/upgrade_prompt_cooldown.dart';

/// Bottom sheet contextual de upgrade (sem dark pattern).
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
  }) => _present(
    context: context,
    featureName: featureName,
    capability: capability,
    requiredPlan: requiredPlan,
    upgradePlano: upgradePlano,
    source: source,
    respectCooldown: false,
  );

  /// Abre a sheet a partir de um erro de entitlement do contrato.
  ///
  /// Devolve `true` se mostrou — o chamador não empilha snackbar de falha em
  /// cima. `false` para qualquer outra coisa: 403 de permissão, cota, 409.
  /// Cota não é entitlement — não abre "desbloqueie o recurso".
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

    await _present(
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

  static Future<void> _present({
    required BuildContext context,
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
    SubscriptionPlan? upgradePlano,
    required String source,
    required bool respectCooldown,
    String? triggerKey,
  }) async {
    final key =
        triggerKey ??
        UpgradePromptCooldown.keyFor(
          capability: capability,
          featureName: featureName,
        );

    final offer = PlanEntitlements.lockedOffer(
      featureName: featureName,
      capability: capability,
      requiredPlan: requiredPlan,
      upgradePlano: upgradePlano,
    );
    final plan = offer.targetPlan ?? SubscriptionPlan.PRO;
    final accent = PaywallCatalog.accentForPlan(plan);
    final body =
        PaywallCatalog.modalMessageFor(
          capability: capability,
          featureName: featureName,
        ) ??
        offer.body;

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = Theme.of(ctx).colorScheme;
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: offer.headline,
                subtitle: body,
                leading: Icon(
                  Icons.lock_outline_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  if (respectCooldown) {
                    UpgradePromptCooldown.markShown(key);
                  }
                  AnalyticsService.instance.track(
                    ProductEvents.paywallCtaTapped,
                    props: {
                      'source': source,
                      'trigger': key,
                      'plan_id': plan.apiName,
                    },
                  );
                  Navigator.pop(ctx);
                  final capQuery =
                      capability != null && capability.isNotEmpty
                          ? '&capability=${Uri.encodeComponent(capability)}'
                          : '';
                  context.push(
                    '/assinatura?plano=${plan.apiName}&source=$source&feature=${Uri.encodeComponent(featureName)}$capQuery',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: EagleTokens.inkDeep,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  offer.ctaLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (respectCooldown) {
                    UpgradePromptCooldown.markShown(key);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Agora não'),
              ),
              if (respectCooldown)
                TextButton(
                  onPressed: () async {
                    await UpgradePromptCooldown.dismissForever(key);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    'Não mostrar novamente',
                    style: TextStyle(
                      color: chrome.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (respectCooldown) {
      await UpgradePromptCooldown.markShown(key);
    }
  }
}
