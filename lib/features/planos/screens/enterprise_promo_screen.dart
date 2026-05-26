import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
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
    setState(() => _starting = true);

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

      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Trial Enterprise ativado. Aproveite os próximos 5 dias.',
          ),
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text('Erro ao ativar trial: $error')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final useStore = subscriptionUsesNativeStore;
    final trialEndDate = DateTime.now().add(const Duration(days: 5));
    final dateStr =
        '${trialEndDate.day.toString().padLeft(2, '0')}/${trialEndDate.month.toString().padLeft(2, '0')}/${trialEndDate.year}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1419), Color(0xFF080C10)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.workspace_premium_outlined,
                  color: primary,
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transforme seu negócio.\nExperimente o Enterprise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                ...const [
                  'Alunos ilimitados',
                  'IA completa + RAG',
                  'White-label com sua marca',
                  'Identidade visual premium',
                  'Automações para escalar a operação',
                ].map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: EagleTokens.good,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
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
                            color: const Color(0xFFF59E0B),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            useStore
                                ? 'Assinatura pela loja'
                                : '5 dias grátis',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        useStore
                            ? 'Ofertas introdutórias são aplicadas pela '
                                '${subscriptionChannelLabel()} ao concluir a compra.'
                            : 'Cancele antes de $dateStr para evitar cobrança.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (!useStore)
                        const Text(
                          'Depois disso: R\$149,90/mês',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FxLiquidPrimaryButton(
                  label:
                      useStore
                          ? 'Continuar na loja'
                          : 'Experimentar 5 dias grátis',
                  loading: _starting,
                  onPressed: _starting ? null : _continueToCheckout,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _dismiss,
                  child: const Text(
                    'Agora não',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
