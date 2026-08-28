import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../constants/aluno_360_layout.dart';

/// Sheet iOS de upgrade — Prioridade do dia / IA Copiloto no Aluno 360.
class Aluno360CopilotUpgradeSheet {
  Aluno360CopilotUpgradeSheet._();

  static Future<void> show(
    BuildContext context, {
    required Color primary,
  }) async {
    final offer = PlanEntitlements.lockedOffer(
      featureName: 'Prioridade do dia',
      capability: 'iaCopiloto',
    );
    final plan = offer.targetPlan ?? SubscriptionPlan.PRO;
    final planLabel = PlanEntitlements.displayPlanName(plan);
    final accent = PaywallCatalog.accentForPlan(plan);
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final sheetDark = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetSurface(
          isDark: sheetDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: sheetDark),
              const SizedBox(height: TokensStrip.s3),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: sheetDark ? 0.18 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: sheetDark ? 0.28 : 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              Text(
                'Prioridade com IA Copiloto',
                textAlign: TextAlign.center,
                style: Aluno360Layout.sectionTitleStyle(ctx, ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                'Gere a sugestão do dia para cada aluno com base no perfil '
                'operacional — disponível no plano $planLabel.',
                textAlign: TextAlign.center,
                style: Aluno360Layout.captionStyle(ctx).copyWith(
                  color: mute,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _UpgradeBenefitRow(
                icon: Icons.bolt_rounded,
                label: 'Prioridade do dia personalizada',
                mute: mute,
                ink: ink,
                accent: primary,
              ),
              const SizedBox(height: 8),
              _UpgradeBenefitRow(
                icon: Icons.psychology_outlined,
                label: 'Sugestões com contexto do Aluno 360',
                mute: mute,
                ink: ink,
                accent: primary,
              ),
              const SizedBox(height: 8),
              _UpgradeBenefitRow(
                icon: Icons.task_alt_rounded,
                label: 'Crie tarefas em um toque',
                mute: mute,
                ink: ink,
                accent: primary,
              ),
              const SizedBox(height: TokensStrip.s4),
              FilledButton(
                onPressed: () {
                  AnalyticsService.instance.track(
                    ProductEvents.paywallCtaTapped,
                    props: {
                      'source': 'aluno360_copilot',
                      'trigger': 'iaCopiloto',
                      'plan_id': plan.apiName,
                    },
                  );
                  Navigator.pop(ctx);
                  context.push(
                    '/assinatura?plano=${plan.apiName}&source=aluno360_copilot&feature=${Uri.encodeComponent('Prioridade do dia')}&capability=iaCopiloto',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: EagleTokens.inkDeep,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  offer.ctaLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Agora não',
                  style: TextStyle(
                    color: mute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpgradeBenefitRow extends StatelessWidget {
  const _UpgradeBenefitRow({
    required this.icon,
    required this.label,
    required this.mute,
    required this.ink,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color mute;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Aluno360Layout.metaStyle(context).copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
