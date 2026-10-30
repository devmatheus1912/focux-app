import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../assinatura/providers/assinatura_provider.dart';
import '../../planos/paywall/paywall_price.dart';
import '../../planos/paywall/trial_eligibility_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../models/subscription_plan.dart';
import '../plan_entitlements.dart';
import '../services/upgrade_prompt_cooldown.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Corpo de venda: ganho, três benefícios, preço real e ação. Usado em folha,
/// tela empilhada e aba.
class FxUpgradeSalesPanel extends ConsumerWidget {
  const FxUpgradeSalesPanel({
    super.key,
    required this.offer,
    required this.benefits,
    required this.plan,
    required this.onCta,
    required this.onVerPlanos,
  });

  final LockedOffer offer;
  final List<UpgradeSalesBenefit> benefits;
  final SubscriptionPlan plan;
  final VoidCallback onCta;
  final VoidCallback onVerPlanos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final atual =
        ref.watch(planoFeaturesProvider).value?.plano ?? SubscriptionPlan.FREE;
    final planos = ref.watch(paywallHomeProvider).value?.planos ?? const [];
    final preco =
        planos
            .where((p) => subscriptionPlanFromApi(p.nome) == plan)
            .firstOrNull
            ?.precoMensal;
    final teste = upgradeTemTeste(
      plan: plan,
      atual: atual,
      elegivel: ref.watch(storeTrialEligibleProvider).value ?? false,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          offer.headline,
          style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        if (atual == SubscriptionPlan.PRO &&
            plan == SubscriptionPlan.ENTERPRISE) ...[
          Text(
            'Você mantém tudo do Pro e ganha isto:',
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        for (final b in benefits.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_rounded, color: primary, size: 20),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Text(
                    b.label,
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          upgradeLinhaDePreco(plan: plan, precoMensal: preco, teste: teste),
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxLiquidPrimaryButton(
          label: teste ? 'Começar $kTrialDays dias grátis' : offer.ctaLabel,
          icon: null,
          onPressed: onCta,
        ),
        const SizedBox(height: TokensStrip.s2),
        FxTonalButton(
          label: 'Ver todos os planos',
          expanded: true,
          onPressed: onVerPlanos,
        ),
      ],
    );
  }
}

bool upgradeTemTeste({
  required SubscriptionPlan plan,
  required SubscriptionPlan atual,
  required bool elegivel,
}) => elegivel && plan == kTrialPlan && atual == SubscriptionPlan.FREE;

/// Preço do catálogo; sem rede, cai só no nome do plano.
String upgradeLinhaDePreco({
  required SubscriptionPlan plan,
  required double? precoMensal,
  required bool teste,
}) {
  final nome = PlanEntitlements.displayPlanName(plan);
  if (precoMensal == null || precoMensal <= 0) return 'Plano $nome';
  final preco = '${formatPaywallBrl(precoMensal)}/mês';
  return teste ? '$kTrialDays dias grátis, depois $preco' : '$nome · $preco';
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
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(
            Icons.lock_outline_rounded,
            color: Theme.of(ctx).colorScheme.primary,
            size: 20,
          ),
          title: featureName,
          child: FxUpgradeSalesPanel(
            offer: offer,
            benefits: benefits,
            plan: plan,
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
            onVerPlanos: () {
              if (respectCooldown) {
                UpgradePromptCooldown.markShown(key);
              }
              FxHomeSheetChrome.dismissAndPop(ctx);
              context.push('/assinatura?source=$source');
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
