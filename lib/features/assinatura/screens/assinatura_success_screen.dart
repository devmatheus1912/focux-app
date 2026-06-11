import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

/// Confirmação pós-compra com próximos passos educativos.
class AssinaturaSuccessScreen extends StatelessWidget {
  final SubscriptionPlan plan;
  final String? transactionId;

  const AssinaturaSuccessScreen({
    super.key,
    required this.plan,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final ink = EagleTokens.darkInk;
    final mute = EagleTokens.darkInkMute;

    return fxScreenA11yScope(
      label: 'Assinatura Success',
      child: FxShellScaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  width: 160,
                  child: RiveAnimation.asset(
                    'assets/animations/confetti_success.riv',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bem-vindo ao ${plan.apiName}!',
                  textAlign: TextAlign.center,
                  style: TokensStrip.h1(color: ink).copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sua assinatura está ativa.',
                  style: TokensStrip.bodyMuted(color: mute),
                ),
                if (transactionId != null && transactionId!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EagleTokens.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EagleTokens.darkLine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID da transação',
                          style: TokensStrip.bodyMuted(color: mute),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transactionId!,
                          style: TextStyle(
                            color: ink,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Você receberá a confirmação no e-mail cadastrado.',
                  textAlign: TextAlign.center,
                  style: TokensStrip.bodyMuted(color: mute),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Próximos passos',
                    style: TokensStrip.h2(color: ink).copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 10),
                ..._nextSteps(plan).map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step,
                            style: TokensStrip.body(color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/dashboard/personal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: EagleTokens.inkDeep,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Começar agora',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<String> _nextSteps(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => [
      'Personalize sua landing completa no editor.',
      'Configure marca própria e domínio.',
      'Abra o IA Copiloto para o primeiro treino assistido.',
    ],
    SubscriptionPlan.ENTERPRISE => [
      'Configure marca própria e identidade visual.',
      'Conecte domínio customizado se tiver.',
      'Use o ${FocuxMicrocopy.commandCenter} para priorizar o dia.',
    ],
    SubscriptionPlan.PREMIUM => [
      'Configure cobrança PIX no chat com alunos.',
      'Abra o IA Copiloto e monte o próximo treino.',
      'Revise inadimplência no financeiro.',
    ],
    _ => ['Explore o dashboard e cadastre seus alunos.'],
  };
}
