import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';

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
    final chrome = ShellChrome.of(context);
    final accent = BrandPalette.softened(PaywallCatalog.accentForPlan(plan));
    final ink = chrome.ink;
    final mute = chrome.mute;

    return fxScreenA11yScope(
      label: 'Assinatura confirmada',
      child: FxShellScaffold(
        useMesh: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s6),
            child: Column(
              children: [
                const SizedBox(height: TokensStrip.s3),
                Semantics(
                  image: true,
                  label: 'Confirmação da assinatura',
                  child: const SizedBox(
                    height: 160,
                    width: 160,
                    child: RiveAnimation.asset(
                      'assets/animations/confetti_success.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Semantics(
                  header: true,
                  child: Text(
                    'Bem-vindo ao ${plan.apiName}!',
                    textAlign: TextAlign.center,
                    style: TokensStrip.h1(color: ink).copyWith(fontSize: 26),
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  'Sua assinatura está ativa.',
                  style: TokensStrip.bodyMuted(color: mute),
                ),
                if (transactionId != null && transactionId!.isNotEmpty) ...[
                  const SizedBox(height: TokensStrip.s4),
                  Semantics(
                    label: 'ID da transação $transactionId',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      decoration: chrome.listCard(),
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
                  ),
                ],
                const SizedBox(height: TokensStrip.s3),
                Text(
                  'Você receberá a confirmação no e-mail cadastrado.',
                  textAlign: TextAlign.center,
                  style: TokensStrip.bodyMuted(color: mute),
                ),
                const SizedBox(height: TokensStrip.s5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Próximos passos',
                      style: TokensStrip.h2(color: ink).copyWith(fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                ..._nextSteps(plan).map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: TokensStrip.s3),
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
                Semantics(
                  button: true,
                  label: 'Começar agora no dashboard',
                  child: FilledButton(
                    onPressed: () => context.go('/dashboard/personal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: EagleTokens.inkDeep,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TokensStrip.rMd),
                      ),
                    ),
                    child: const Text(
                      'Começar agora',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
    SubscriptionPlan.ENTERPRISE => [
      'Personalize sua landing completa no editor.',
      'Configure marca própria e domínio.',
      'Abra o IA Copiloto para o primeiro treino assistido.',
    ],
    SubscriptionPlan.PRO => [
      'Configure cobrança PIX no chat com alunos.',
      'Abra o IA Copiloto e monte o próximo treino.',
      'Revise inadimplência no financeiro.',
    ],
    _ => ['Explore o dashboard e cadastre seus alunos.'],
  };
}
