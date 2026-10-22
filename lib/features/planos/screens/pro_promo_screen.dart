import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/focux_hub_typography.dart';
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
import '../../../features/subscription/store_subscription_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../paywall/paywall_price.dart';
import '../paywall/trial_eligibility_provider.dart';

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
    final primary = Theme.of(context).colorScheme.primary;
    final useStore = subscriptionUsesNativeStore;
    final trial =
        useStore && (ref.watch(storeTrialEligibleProvider).value ?? false);
    final l10n = S.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return fxScreenA11yScope(
      label: 'Promoção PRO',
      child: FxShellScaffold(
        useMesh: true,
        appBar: const FxShellAppBar(
          title: 'PRO',
          fallbackLocation: '/planos',
        ),
        body: SafeArea(
            child:
                _starting
                    ? const SkeletonList(count: 4)
                    : _error != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      title: 'Não foi possível continuar',
                      message: _error!,
                      onRetry: _continueToCheckout,
                    )
                    : Padding(
                      padding: const EdgeInsets.all(TokensStrip.s7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            trial
                                ? l10n.proPromoTituloTrial(
                                  kTrialDays,
                                  subscriptionChannelWith(
                                    ChannelPreposition.em,
                                  ),
                                )
                                : l10n.proPromoTitulo,
                            style: FocuxHubTypography.pageTitle(
                              context,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          Text(
                            trial
                                ? l10n.proPromoTextoTrial(
                                  subscriptionCancelWhere(),
                                )
                                : useStore
                                ? l10n.proPromoTextoLoja(
                                  subscriptionCancelWhere(),
                                )
                                : l10n.proPromoTextoWeb,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.bodyMuted(color: mute),
                          ),
                          const Spacer(),
                          const SizedBox(height: TokensStrip.s5),
                          Semantics(
                            button: true,
                            label:
                                trial
                                    ? l10n.proPromoCtaTrial(kTrialDays)
                                    : l10n.proPromoCta,
                            child: FxLiquidPrimaryButton(
                              label:
                                  trial
                                      ? l10n.proPromoCtaTrial(kTrialDays)
                                      : l10n.proPromoCta,
                              loading: _starting,
                              onPressed: _starting ? null : _continueToCheckout,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          FxConversionTextLink(
                            text: '',
                            actionText: l10n.proPromoAgoraNao,
                            onTap: _dismiss,
                            actionColor: mute,
                          ),
                          const SizedBox(height: TokensStrip.s2),
                        ],
                      ),
                    ),
            ),
        ),
    );
  }
}
