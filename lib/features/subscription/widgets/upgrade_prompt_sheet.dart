import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../models/subscription_plan.dart';
import '../plan_entitlements.dart';
import '../services/upgrade_prompt_cooldown.dart';

/// Bottom sheet contextual de upgrade (sem dark pattern).
class UpgradePromptSheet {
  UpgradePromptSheet._();

  static Future<void> showIfAllowed({
    required BuildContext context,
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
  }) async {
    final triggerKey = UpgradePromptCooldown.keyFor(
      capability: capability,
      featureName: featureName,
    );
    if (!await UpgradePromptCooldown.shouldShow(triggerKey)) return;
    if (!context.mounted) return;

    final offer = PlanEntitlements.lockedOffer(
      featureName: featureName,
      capability: capability,
      requiredPlan: requiredPlan,
    );
    final plan = offer.targetPlan ?? SubscriptionPlan.PREMIUM;
    final accent = PaywallCatalog.accentForPlan(plan);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EagleTokens.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EagleTokens.darkLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                offer.headline,
                style: TokensStrip.h2(color: EagleTokens.darkInk),
              ),
              const SizedBox(height: 10),
              Text(
                offer.body,
                style: TokensStrip.body(color: EagleTokens.darkInkMute),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  UpgradePromptCooldown.markShown(triggerKey);
                  AnalyticsService.instance.track(
                    ProductEvents.paywallCtaTapped,
                    props: {
                      'source': 'upgrade_prompt',
                      'trigger': triggerKey,
                      'plan_id': plan.apiName,
                    },
                  );
                  Navigator.pop(ctx);
                  context.push(
                    '/assinatura?plano=${plan.apiName}&source=upgrade_prompt&feature=${Uri.encodeComponent(featureName)}',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: const Color(0xFF081012),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(offer.ctaLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              TextButton(
                onPressed: () {
                  UpgradePromptCooldown.markShown(triggerKey);
                  Navigator.pop(ctx);
                },
                child: const Text('Agora não'),
              ),
              TextButton(
                onPressed: () async {
                  await UpgradePromptCooldown.dismissForever(triggerKey);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  'Não mostrar novamente',
                  style: TextStyle(color: EagleTokens.darkInkMute.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        );
      },
    );

    await UpgradePromptCooldown.markShown(triggerKey);
  }
}
