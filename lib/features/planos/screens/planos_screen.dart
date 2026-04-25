import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/planos_repository.dart';

class PlanosScreen extends ConsumerStatefulWidget {
  const PlanosScreen({super.key});

  @override
  ConsumerState<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends ConsumerState<PlanosScreen> {
  bool _startingTrial = false;

  Future<void> _startTrial() async {
    if (_startingTrial) return;

    setState(() => _startingTrial = true);
    try {
      await PlanosRepository(ref.read(apiClientProvider)).startTrial(
        payload: buildLocalSubscriptionMetadata(
          productId: 'focux_enterprise_trial',
        ).toTrialPayload(),
      );
      ref.invalidate(perfilProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trial Enterprise ativado. Voce ja pode usar os recursos avancados.'),
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ativar trial: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _startingTrial = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;
    final trialEndsAt = perfil?.trialEndsAt;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Planos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha o plano ideal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monte a operacao do seu negocio no ritmo certo e faca o upgrade quando fizer sentido.',
              style: TextStyle(
                color:
                    isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                height: 1.45,
              ),
            ),
            if (currentPlan == SubscriptionPlan.ENTERPRISE &&
                trialEndsAt != null &&
                trialEndsAt.isAfter(DateTime.now())) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EagleTokens.good.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EagleTokens.good.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: EagleTokens.good,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Trial Enterprise ativo ate ${_formatDate(trialEndsAt)}.',
                        style: TextStyle(
                          color: EagleTokens.good,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _PlanCard(
              name: 'FREE',
              price: 'Gratis',
              isCurrent: currentPlan == SubscriptionPlan.FREE,
              isDark: isDark,
              accentColor: const Color(0xFF6B7280),
              features: const [
                'Ate 5 alunos',
                'Treinos e agenda basicos',
                'Sem IA avancada',
                'Sem landing page',
              ],
            ),
            const SizedBox(height: 16),
            _PlanCard(
              name: 'PREMIUM',
              price: 'R\$79/mes',
              isCurrent: currentPlan == SubscriptionPlan.PREMIUM,
              isDark: isDark,
              accentColor: const Color(0xFF3B5FE2),
              features: const [
                'Ate 20 alunos',
                'Financeiro e CRM',
                'Migracao Magica IA',
                'Landing page com marca Focux',
              ],
              cta: currentPlan != SubscriptionPlan.PREMIUM
                  ? ElevatedButton(
                      onPressed: () => context.push(
                        '/assinatura',
                        extra: SubscriptionPlan.PREMIUM.apiName,
                      ),
                      child: const Text('Assinar Premium'),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EagleTokens.brand.withValues(alpha: 0.28),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _PlanCard(
                name: 'ENTERPRISE',
                price: 'R\$149,90/mes',
                isCurrent: currentPlan == SubscriptionPlan.ENTERPRISE,
                isDark: isDark,
                accentColor: EagleTokens.brand,
                features: const [
                  'Alunos ilimitados',
                  'IA ilimitada + RAG',
                  'White-label completo',
                  'Dominio customizado',
                  'Landing page e prova social',
                  'Suporte prioritario',
                ],
                cta: currentPlan != SubscriptionPlan.ENTERPRISE
                    ? Column(
                        children: [
                          if (!trialUsed) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: EagleTokens.good.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    color: EagleTokens.good,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '5 dias gratis disponiveis',
                                    style: TextStyle(
                                      color: EagleTokens.good,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed:
                                    _startingTrial ? null : _startTrial,
                                style: FilledButton.styleFrom(
                                  backgroundColor: EagleTokens.brand,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _startingTrial
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Experimentar 5 dias gratis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cancele antes do vencimento para evitar cobranca.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute,
                              ),
                            ),
                          ],
                          if (trialUsed) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.push(
                                  '/assinatura',
                                  extra: SubscriptionPlan.ENTERPRISE.apiName,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: EagleTokens.brand,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Assinar Enterprise',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final bool isCurrent;
  final bool isDark;
  final Color accentColor;
  final List<String> features;
  final Widget? cta;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.isCurrent,
    required this.isDark,
    required this.accentColor,
    required this.features,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? accentColor
              : (isDark ? EagleTokens.darkLine : EagleTokens.line),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? accentColor : null,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Atual',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cta != null) ...[
            const SizedBox(height: 16),
            cta!,
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
