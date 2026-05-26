import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/ia_repository.dart';

/// Paywall contextual quando a cota de IA esgota ou o plano não inclui IA.
class IaQuotaUpgrade {
  IaQuotaUpgrade._();

  static bool shouldPromptUpgrade(IaOperationalException error) =>
      error.suggestsUpgrade;

  static bool isBlockedLocally(PlanoFeatures? features) {
    if (features == null || !features.iaCopiloto) return true;
    return features.iaQuotaEsgotada;
  }

  static LockedOffer offerFor({
    IaOperationalException? error,
    PlanoFeatures? features,
  }) {
    if (error != null && error.suggestsUpgrade) {
      return PlanEntitlements.iaQuotaUpgradeOffer(
        currentPlan: error.suggestedUpgradePlan != null
            ? _inferCurrentFromUpgrade(error)
            : (features?.plano ?? SubscriptionPlan.FREE),
        targetPlan: error.suggestedUpgradePlan,
        limiteAtual: features?.limiteIaMensal,
      );
    }
    final plano = features?.plano ?? SubscriptionPlan.FREE;
    if (features == null || !features.iaCopiloto) {
      return PlanEntitlements.lockedOffer(
        featureName: 'IA Copiloto',
        capability: 'iaCopiloto',
      );
    }
    return PlanEntitlements.iaQuotaUpgradeOffer(
      currentPlan: plano,
      limiteAtual: features.limiteIaMensal,
    );
  }

  static SubscriptionPlan _inferCurrentFromUpgrade(IaOperationalException error) {
    final target = error.suggestedUpgradePlan;
    if (target == SubscriptionPlan.ENTERPRISE) {
      return SubscriptionPlan.PREMIUM;
    }
    return SubscriptionPlan.FREE;
  }

  static Future<bool> showUpgradeDialog(
    BuildContext context, {
    IaOperationalException? error,
    PlanoFeatures? features,
  }) async {
    final offer = offerFor(error: error, features: features);
    if (error == null && features != null && !features.iaQuotaEsgotada && features.iaCopiloto) {
      return false;
    }

    await AnalyticsService.instance.track(
      ProductEvents.iaQuotaExhausted,
      props: {
        'codigo': error?.codigo ?? 'local_quota',
        if (features != null) 'plano': features.plano.apiName,
        if (offer.targetPlan != null) 'upgradePlano': offer.targetPlan!.apiName,
      },
    );

    if (!context.mounted) return false;

    final upgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                offer.headline,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(offer.body, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 20),
              if (offer.targetPlan != null)
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(offer.ctaLabel),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Entendi'),
                ),
              if (offer.targetPlan != null)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Agora não'),
                ),
            ],
          ),
        ),
      ),
    );

    if (upgrade == true && offer.targetPlan != null && context.mounted) {
      context.push('/assinatura', extra: offer.targetPlan!.apiName);
      return true;
    }
    return false;
  }

  /// Antes de chamar a IA: bloqueia localmente se a cota já esgotou.
  static Future<bool> guardBeforeRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final features = ref.read(planoFeaturesProvider).valueOrNull;
    if (features == null || !isBlockedLocally(features)) return true;
    await showUpgradeDialog(context, features: features);
    return false;
  }

  /// Depois de erro 403 estruturado do backend.
  static Future<void> handleError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) async {
    if (error is! IaOperationalException || !shouldPromptUpgrade(error)) {
      return;
    }
    await showUpgradeDialog(
      context,
      error: error,
      features: ref.read(planoFeaturesProvider).valueOrNull,
    );
    await ref.read(planoFeaturesProvider.notifier).refresh();
  }
}
