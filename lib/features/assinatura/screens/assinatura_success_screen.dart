import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
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
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s6),
                  child: Column(
                    children: [
                      const SizedBox(height: TokensStrip.s3),
                      Semantics(
                        image: true,
                        label: 'Confirmação da assinatura',
                        child: _SuccessBadge(accent: accent),
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Semantics(
                        header: true,
                        child: Text(
                          'Bem-vindo ao ${plan.apiName}!',
                          textAlign: TextAlign.center,
                          style: TokensStrip.h1(
                            color: ink,
                          ).copyWith(fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        'Sua assinatura está ativa.',
                        style: TokensStrip.bodyMuted(color: mute),
                      ),
                      if (transactionId != null &&
                          transactionId!.isNotEmpty) ...[
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
                            style: TokensStrip.h2(
                              color: ink,
                            ).copyWith(fontSize: 17),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      ..._nextSteps(plan).map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: TokensStrip.s3,
                          ),
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
                        child: FxLiquidPrimaryButton(
                          label: 'Começar agora',
                          onPressed: () => context.go('/dashboard/personal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _nextSteps(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE => [
      'Personalize sua landing completa no editor.',
      'Configure sua marca própria: logo e cores.',
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

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final reduced = TokensStrip.prefersReducedMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0.6, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder:
          (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.14),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
      ),
    );
  }
}
