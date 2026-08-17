import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../../../features/subscription/utils/plano_ia_limits.dart';
import '../../../features/subscription/store_subscription_policy.dart';
import '../data/planos_repository.dart';

class EnterprisePromoScreen extends ConsumerStatefulWidget {
  const EnterprisePromoScreen({super.key});

  @override
  ConsumerState<EnterprisePromoScreen> createState() =>
      _EnterprisePromoScreenState();
}

class _EnterprisePromoScreenState extends ConsumerState<EnterprisePromoScreen> {
  bool _starting = false;
  String? _error;

  Future<void> _markPromoAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final personalId = ref.read(perfilProvider).valueOrNull?.id;
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

      if (subscriptionUsesNativeStore) {
        await context.push(
          '/assinatura',
          extra: SubscriptionPlan.ENTERPRISE.apiName,
        );
        return;
      }

      await PlanosRepository(ref.read(apiClientProvider)).startTrial(
        payload:
            buildLocalSubscriptionMetadata(
              productId: 'focux_enterprise_trial',
            ).toTrialPayload(),
      );
      ref.invalidate(perfilProvider);
      if (!mounted) return;

      FeedbackHelper.showSuccess(
        context,
        'Trial Enterprise ativado. Aproveite os próximos 5 dias.',
      );
      context.go('/dashboard/personal');
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
    final trialEndDate = DateTime.now().add(const Duration(days: 5));
    final dateStr =
        '${trialEndDate.day.toString().padLeft(2, '0')}/${trialEndDate.month.toString().padLeft(2, '0')}/${trialEndDate.year}';
    // Promo surface is always cinematic dark — force readable ink.
    const ink = EagleTokens.darkInk;
    const mute = EagleTokens.darkInkMute;

    return fxScreenA11yScope(
      label: 'Promoção Enterprise',
      child: FxShellScaffold(
        useMesh: true,
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
                    ? const FxLoading()
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
                            'Transforme seu negócio.\nExperimente o Enterprise.',
                            textAlign: TextAlign.center,
                            style: TokensStrip.h1(
                              color: ink,
                            ).copyWith(fontSize: 26, height: 1.2),
                          ),
                          const SizedBox(height: TokensStrip.s8),
                          ...[
                            'Alunos ilimitados',
                            '${PlanoIaLimits.enterprise} interações de IA/mês',
                            'Marca própria com sua marca',
                            'Identidade visual premium',
                            'Automações para escalar a operação',
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
                                          ? 'Assinatura pela loja'
                                          : '5 dias grátis',
                                      style: TokensStrip.h2(
                                        color: EagleTokens.goldStar,
                                      ).copyWith(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TokensStrip.s1),
                                Text(
                                  useStore
                                      ? 'Ofertas introdutórias são aplicadas pela '
                                          '${subscriptionChannelLabel()} ao concluir a compra.'
                                      : 'Cancele antes de $dateStr para evitar cobrança.',
                                  textAlign: TextAlign.center,
                                  style: TokensStrip.bodyMuted(color: mute),
                                ),
                                if (!useStore)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Depois disso: R\$149,90/mês',
                                      textAlign: TextAlign.center,
                                      style: TokensStrip.bodyMuted(
                                        color: mute,
                                      ).copyWith(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          Semantics(
                            button: true,
                            label:
                                useStore
                                    ? 'Continuar na loja'
                                    : 'Experimentar 5 dias grátis',
                            child: FxLiquidPrimaryButton(
                              label:
                                  useStore
                                      ? 'Continuar na loja'
                                      : 'Experimentar 5 dias grátis',
                              loading: _starting,
                              onPressed:
                                  _starting ? null : _continueToCheckout,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          Semantics(
                            button: true,
                            label: 'Agora não',
                            child: TextButton(
                              onPressed: _dismiss,
                              child: Text(
                                'Agora não',
                                style: TokensStrip.bodyMuted(
                                  color: mute,
                                ).copyWith(fontSize: 14),
                              ),
                            ),
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
