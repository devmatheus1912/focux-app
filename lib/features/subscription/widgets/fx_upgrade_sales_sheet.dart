import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../models/subscription_plan.dart';
import '../plan_entitlements.dart';
import '../services/upgrade_prompt_cooldown.dart';

/// Corpo de venda reutilizável (sheet Free + FeatureGate).
class FxUpgradeSalesPanel extends StatelessWidget {
  const FxUpgradeSalesPanel({
    super.key,
    required this.offer,
    required this.benefits,
    required this.plan,
    required this.onCta,
    this.onDismiss,
    this.priceAnchor,
    this.compact = false,
  });

  final LockedOffer offer;
  final List<UpgradeSalesBenefit> benefits;
  final SubscriptionPlan plan;
  final VoidCallback onCta;
  final VoidCallback? onDismiss;
  final String? priceAnchor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final accent = PaywallCatalog.tierAccentOnSurface(
      plan,
      isDark: chrome.isDark,
    );
    final planLabel = PlanEntitlements.displayPlanName(plan);
    final roi = PaywallCatalog.roiTagForPlan(plan);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: chrome.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withValues(alpha: chrome.isDark ? 0.45 : 0.28),
              ),
            ),
            child: Text(
              'Incluso no $planLabel',
              style: FocuxHubTypography.bodyMuted(
                color: accent,
                fontWeight: FontWeight.w800,
              ).copyWith(fontSize: 12, letterSpacing: 0.2),
            ),
          ),
        ),
        SizedBox(height: compact ? TokensStrip.s2 : TokensStrip.s3),
        Text(
          offer.headline,
          style: FocuxHubTypography.sectionTitle(context, color: ink).copyWith(
            fontSize: compact ? 20 : 22,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          offer.body,
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w600,
          ).copyWith(height: 1.4),
        ),
        SizedBox(height: compact ? TokensStrip.s3 : TokensStrip.s4),
        for (var i = 0; i < benefits.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 8 : 10),
          _BenefitRow(benefit: benefits[i], accent: accent, ink: ink, mute: mute),
        ],
        if (priceAnchor != null || roi != null) ...[
          SizedBox(height: compact ? TokensStrip.s3 : TokensStrip.s4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: chrome.isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: chrome.isDark ? 0.28 : 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (priceAnchor != null)
                  Text(
                    priceAnchor!,
                    style: FocuxHubTypography.cardTitle(color: ink).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (roi != null) ...[
                  if (priceAnchor != null) const SizedBox(height: 4),
                  Text(
                    roi,
                    style: FocuxHubTypography.bodyMuted(
                      color: mute,
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 12, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? TokensStrip.s3 : TokensStrip.s4),
        FxLiquidPrimaryButton(
          label: offer.ctaLabel,
          icon: Icons.workspace_premium_rounded,
          onPressed: onCta,
        ),
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: Text(
              'Agora não',
              style: TextStyle(color: mute, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.benefit,
    required this.accent,
    required this.ink,
    required this.mute,
  });

  final UpgradeSalesBenefit benefit;
  final Color accent;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(benefit.icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefit.label,
                style: FocuxHubTypography.cardTitle(color: ink).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                benefit.detail,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sheet canônico de conversão Free → Pro/Enterprise.
abstract final class FxUpgradeSalesSheet {
  FxUpgradeSalesSheet._();

  static Future<void> show({
    required BuildContext context,
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
    SubscriptionPlan? upgradePlano,
    String source = 'upgrade_prompt',
    bool respectCooldown = false,
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
    final benefits = PlanEntitlements.salesBenefits(
      capability: capability,
      featureName: featureName,
      plan: plan,
    );
    final bodyOverride = PaywallCatalog.modalMessageFor(
      capability: capability,
      featureName: featureName,
    );
    final enriched = LockedOffer(
      headline: offer.headline,
      body: bodyOverride ?? offer.body,
      ctaLabel: offer.ctaLabel,
      targetPlan: plan,
    );
    final accent = PaywallCatalog.tierAccentOnSurface(
      plan,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final priceAnchor = switch (plan) {
      SubscriptionPlan.ENTERPRISE => 'Enterprise · marca, loja e time',
      SubscriptionPlan.PRO => 'Pro · a partir da assinatura mensal',
      _ => null,
    };
    final planLabel = PlanEntitlements.displayPlanName(plan);

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetScaffold(
          isDark: isDark,
          leading: Container(
            width: FxHomeSheetChrome.leadingSize,
            height: FxHomeSheetChrome.leadingSize,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.4 : 0.22),
              ),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: accent,
              size: 20,
            ),
          ),
          title: 'Desbloqueie no $planLabel',
          subtitle: featureName,
          child: FxUpgradeSalesPanel(
            offer: enriched,
            benefits: benefits,
            plan: plan,
            priceAnchor: priceAnchor,
            onCta: () {
              if (respectCooldown) {
                UpgradePromptCooldown.markShown(key);
              }
              AnalyticsService.instance.track(
                ProductEvents.paywallCtaTapped,
                props: {
                  'source': source,
                  'trigger': key,
                  'plan_id': plan.apiName,
                  if (capability != null) 'capability': capability,
                },
              );
              FxHomeSheetChrome.dismissAndPop(ctx);
              final capQuery =
                  capability != null && capability.isNotEmpty
                      ? '&capability=${Uri.encodeComponent(capability)}'
                      : '';
              context.push(
                '/assinatura?plano=${plan.apiName}&source=$source&feature=${Uri.encodeComponent(featureName)}$capQuery',
              );
            },
            onDismiss: () {
              if (respectCooldown) {
                UpgradePromptCooldown.markShown(key);
              }
              FxHomeSheetChrome.dismissAndPop(ctx);
            },
          ),
        );
      },
    );

    if (respectCooldown) {
      await UpgradePromptCooldown.markShown(key);
    }
  }
}
