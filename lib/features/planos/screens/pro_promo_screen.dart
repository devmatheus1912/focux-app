import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../../../features/subscription/utils/plano_ia_limits.dart';
import '../../../features/subscription/store_subscription_policy.dart';
import '../paywall/paywall_price.dart';

class ProPromoScreen extends ConsumerStatefulWidget {
  const ProPromoScreen({super.key});

  @override
  ConsumerState<ProPromoScreen> createState() =>
      _ProPromoScreenState();
}

class _ProPromoScreenState extends ConsumerState<ProPromoScreen> {
  bool _starting = false;
  String? _error;

  Future<void> _markPromoAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final personalId = ref.read(perfilProvider).value?.id;
    if (personalId != null) {
      await prefs.setBool('promo_shown_$personalId', true);
    }
  }

  Future<void> _dismiss() async {
    await _markPromoAsSeen();
    if (mounted) {
      context.go('/dashboard/personal');
    }
  }

  Future<void> _continueToCheckout() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      await _markPromoAsSeen();
      if (!mounted) return;
      await context.push('/assinatura', extra: kTrialPlan.apiName);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = BrandPalette.softened(
      Theme.of(context).colorScheme.primary,
    );
    final useStore = subscriptionUsesNativeStore;
    // Promo surface is always cinematic dark — force readable ink.
    const ink = EagleTokens.darkInk;
    const mute = EagleTokens.darkInkMute;

    return fxScreenA11yScope(
      label: 'Promoção PRO',
      child: FxShellScaffold(
        useMesh: true,
        appBar: const FxShellAppBar(
          title: 'PRO',
          fallbackLocation: '/planos',
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [EagleTokens.cinematicBgHi, EagleTokens.cinematicBg],
            ),
          ),
          child: SafeArea(
            child:
                _starting
                    ? const SkeletonList(count: 4)
                    : _error != null
                    ? FxErrorState(
                      chromeOnDark: true,
                      primary: primary,
                      title: 'Não foi possível continuar',
                      message: _error!,
                      onRetry: _continueToCheckout,
                    )
                    : Padding(
                      padding: const EdgeInsets.all(TokensStrip.s7),
                      child: Column(
                        children: [
                          const Spacer(),
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: primary,
                            size: 56,
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          Text(
                            useStore
                                ? 'PRO com $kTrialDays dias grátis\n${subscriptionChannelWith(ChannelPreposition.em)}'
                                : 'Cresça e cobre no app.\nAssine o PRO.',
                            textAlign: TextAlign.center,
                            style: TokensStrip.h1(
                              color: ink,
                            ).copyWith(fontSize: 26, height: 1.2),
                          ),
                          const SizedBox(height: TokensStrip.s8),
                          ...[
                            'Até 30 alunos',
                            '${PlanoIaLimits.pro} interações de IA/mês',
                            'Cobrança PIX dos alunos no app',
                            'CRM de leads',
                            'Relatórios, hábitos e feedback em vídeo',
                          ].map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: TokensStrip.s3,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: EagleTokens.good,
                                    size: 20,
                                  ),
                                  const SizedBox(width: TokensStrip.s3),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: TokensStrip.body(color: ink),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            decoration: chrome.panel(
                              accent: EagleTokens.goldStar,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      useStore
                                          ? Icons.storefront_outlined
                                          : Icons.card_giftcard,
                                      color: EagleTokens.goldStar,
                                      size: 22,
                                    ),
                                    const SizedBox(width: TokensStrip.s2),
                                    Text(
                                      useStore
                                          ? '$kTrialDays dias grátis na loja'
                                          : 'Plano PRO',
                                      style: FocuxHubTypography.sectionTitle(
                                        context,
                                        color: EagleTokens.goldStar,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TokensStrip.s1),
                                Text(
                                  useStore
                                      ? 'A loja mostra o período grátis e o valor antes de você confirmar. Cancele quando quiser nas assinaturas do aparelho.'
                                      : 'Checkout seguro via Mercado Pago. Cancele quando quiser.',
                                  textAlign: TextAlign.center,
                                  style: TokensStrip.bodyMuted(color: mute),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          Semantics(
                            button: true,
                            label:
                                useStore
                                    ? 'Começar $kTrialDays dias grátis na loja'
                                    : 'Assinar o PRO',
                            child: FxLiquidPrimaryButton(
                              label:
                                  useStore
                                      ? 'Começar $kTrialDays dias grátis'
                                      : 'Assinar o PRO',
                              loading: _starting,
                              onPressed: _starting ? null : _continueToCheckout,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          FxConversionTextLink(
                            text: '',
                            actionText: 'Agora não',
                            onTap: _dismiss,
                            actionColor: mute,
                          ),
                          const SizedBox(height: TokensStrip.s2),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
