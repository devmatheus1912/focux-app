import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/planos_repository.dart';
import '../../../core/widgets/feedback_helper.dart';

class PlanosScreen extends ConsumerStatefulWidget {
  const PlanosScreen({super.key});

  @override
  ConsumerState<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends ConsumerState<PlanosScreen> {
  bool _startingTrial = false;

  Future<void> _startTrial() async {
    if (_startingTrial) return;
    HapticFeedback.mediumImpact();
    setState(() => _startingTrial = true);
    try {
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
            'Trial Enterprise ativado. Você já pode usar os recursos avançados.',
          ),
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(
          error,
          fallback: 'Não foi possível ativar o trial. Tente novamente.',
        ),
      );
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;
    final trialEndsAt = perfil?.trialEndsAt;
    final trialAtivo =
        trialEndsAt != null && trialEndsAt.isAfter(DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Planos',
        subtitle: 'ASSINATURA',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: FxPremiumEntrance(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 4, TokensStrip.s5, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Escolha o plano ideal',
                  style: AppTypography.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monte a operação do seu negócio no ritmo certo e faça o upgrade quando fizer sentido.',
                style: TextStyle(color: mute, height: 1.45),
              ),

              if (trialAtivo) ...[
                const SizedBox(height: TokensStrip.s4),
                _TrialActiveBanner(endsAt: trialEndsAt),
              ],

              const SizedBox(height: TokensStrip.s5),

              FxStaggerItem(
                index: 0,
                child: _PlanCard(
                  isDark: isDark,
                  name: 'FREE',
                  price: 'Grátis',
                  accentColor:
                      isDark
                          ? EagleTokens.darkInkMute
                          : TokensStrip.textSecondary,
                  isCurrent: currentPlan == SubscriptionPlan.FREE,
                  glow: false,
                  features: const [
                    _Feature('Até 5 alunos', included: true),
                    _Feature('Treinos e agenda básicos', included: true),
                    _Feature('IA avançada', included: false),
                    _Feature('Financeiro e CRM', included: false),
                    _Feature('White-label', included: false),
                  ],
                  ctaLabel:
                      currentPlan == SubscriptionPlan.FREE ? 'Plano atual' : null,
                ),
              ),

              const SizedBox(height: TokensStrip.s4),

              FxStaggerItem(
                index: 1,
                child: _PlanCard(
                  isDark: isDark,
                  name: 'PREMIUM',
                  price: 'R\$ 79,00/mês',
                  accentColor: primary,
                  isCurrent: currentPlan == SubscriptionPlan.PREMIUM,
                  glow: currentPlan != SubscriptionPlan.PREMIUM,
                  badge:
                      !trialUsed && currentPlan == SubscriptionPlan.FREE
                          ? _PlanBadge(
                            label: '5 dias grátis',
                            color: EagleTokens.good,
                          )
                          : null,
                  features: const [
                    _Feature('Até 20 alunos', included: true),
                    _Feature('Financeiro e CRM', included: true),
                    _Feature('Migração Mágica IA', included: true),
                    _Feature('Identidade visual premium', included: true),
                    _Feature('White-label', included: false),
                    _Feature('IA ilimitada + RAG', included: false),
                  ],
                  cta:
                      currentPlan != SubscriptionPlan.PREMIUM &&
                              currentPlan.level < SubscriptionPlan.PREMIUM.level
                          ? _PrimaryButton(
                            label: 'Assinar Premium',
                            semanticsLabel: 'Assinar plano Premium',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.push(
                                '/assinatura',
                                extra: SubscriptionPlan.PREMIUM.apiName,
                              );
                            },
                          )
                          : null,
                  ctaLabel:
                      currentPlan == SubscriptionPlan.PREMIUM
                          ? 'Plano atual'
                          : null,
                ),
              ),

              const SizedBox(height: TokensStrip.s4),

              FxStaggerItem(
                index: 2,
                child: _EnterpriseCard(
                  isDark: isDark,
                  isCurrent: currentPlan == SubscriptionPlan.ENTERPRISE,
                  trialUsed: trialUsed,
                  trialAtivo: trialAtivo,
                  startingTrial: _startingTrial,
                  onTrial: _startTrial,
                  onAssinar: () {
                    HapticFeedback.selectionClick();
                    context.push(
                      '/assinatura',
                      extra: SubscriptionPlan.ENTERPRISE.apiName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialActiveBanner extends StatelessWidget {
  final DateTime endsAt;
  const _TrialActiveBanner({required this.endsAt});

  @override
  Widget build(BuildContext context) {
    final remaining = endsAt.difference(DateTime.now()).inDays;
    return Semantics(
      container: true,
      label:
          'Trial Enterprise ativo até ${_fmtDate(endsAt)}. $remaining dias restantes.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EagleTokens.good.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EagleTokens.good.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: EagleTokens.good, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trial Enterprise ativo até ${_fmtDate(endsAt)}.',
                    style: const TextStyle(
                      color: EagleTokens.good,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$remaining dias restantes. Sem cobrança até o término.',
                    style: const TextStyle(color: EagleTokens.good, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool isDark;
  final String name, price;
  final Color accentColor;
  final bool isCurrent;
  final List<_Feature> features;
  final Widget? cta;
  final String? ctaLabel;
  final _PlanBadge? badge;
  final bool glow;

  const _PlanCard({
    required this.isDark,
    required this.name,
    required this.price,
    required this.accentColor,
    required this.isCurrent,
    required this.features,
    this.cta,
    this.ctaLabel,
    this.badge,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final includedCount = features.where((f) => f.included).length;
    final a11y =
        isCurrent
            ? 'Plano $name, $price. Plano atual. $includedCount de ${features.length} recursos incluídos.'
            : 'Plano $name, $price. $includedCount de ${features.length} recursos incluídos.';

    final card = Semantics(
      container: true,
      label: a11y,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: fxListCardDecoration(
          context,
          accent: isCurrent ? accentColor : null,
        ).copyWith(
          border: Border.all(
            color: isCurrent ? accentColor : line,
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
                      color: isCurrent ? accentColor : ink,
                    ),
                  ),
                ),
                if (badge != null) ...[badge!, const SizedBox(width: 6)],
                if (isCurrent) _ChipBadge(label: 'Atual', color: accentColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 14),
            ...features.map(
              (f) => _FeatureRow(feature: f, accent: accentColor, isDark: isDark),
            ),
            if (cta != null) ...[const SizedBox(height: TokensStrip.s4), cta!],
            if (ctaLabel != null && cta == null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  ctaLabel!,
                  style: TextStyle(
                    color: mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!glow) return card;
    return FxGlowSurface(color: accentColor, enabled: glow, child: card);
  }
}

class _EnterpriseCard extends StatelessWidget {
  final bool isDark, isCurrent, trialUsed, trialAtivo, startingTrial;
  final VoidCallback onTrial, onAssinar;

  const _EnterpriseCard({
    required this.isDark,
    required this.isCurrent,
    required this.trialUsed,
    required this.trialAtivo,
    required this.startingTrial,
    required this.onTrial,
    required this.onAssinar,
  });

  static const _accent = Color(0xFFC49A2A);

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      container: true,
      label:
          isCurrent
              ? 'Plano Enterprise, R\$ 149,90 por mês. Plano atual.'
              : 'Plano Enterprise, R\$ 149,90 por mês.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: fxListCardDecoration(
            context,
            accent: isCurrent ? _accent : null,
          ).copyWith(
            border: Border.all(
              color: isCurrent ? _accent : line,
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
                      'ENTERPRISE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ),
                  if (!trialUsed && !isCurrent)
                    const _PlanBadge(
                      label: '5 dias grátis',
                      color: EagleTokens.good,
                    ),
                  if (!trialUsed && !isCurrent) const SizedBox(width: 6),
                  if (isCurrent) const _ChipBadge(label: 'Atual', color: _accent),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'R\$ 149,90/mês',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 14),
              ...[
                const _Feature('Alunos ilimitados', included: true),
                const _Feature('IA ilimitada + RAG', included: true),
                const _Feature('White-label completo', included: true),
                const _Feature('Domínio customizado', included: true),
                const _Feature('Identidade visual + white-label', included: true),
                const _Feature('Suporte prioritário', included: true),
              ].map((f) => _FeatureRow(feature: f, accent: _accent, isDark: isDark)),

              if (!isCurrent) ...[
                const SizedBox(height: 20),
                if (!trialUsed && !trialAtivo) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EagleTokens.goodSoft.withValues(
                        alpha: isDark ? 0.08 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EagleTokens.good.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_outlined,
                              color: EagleTokens.good,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '5 dias grátis disponíveis',
                              style: const TextStyle(
                                color: EagleTokens.good,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _TrialInfoRow(
                          icon: Icons.credit_card_outlined,
                          text:
                              'É obrigatório cadastrar um cartão de crédito para ativar o período gratuito.',
                        ),
                        const SizedBox(height: 4),
                        _TrialInfoRow(
                          icon: Icons.lock_outline,
                          text:
                              'Nenhuma cobrança até o término dos 5 dias. Cancele antes sem custo.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'Experimentar 5 dias grátis',
                    loadingLabel: 'Ativando…',
                    loading: startingTrial,
                    semanticsLabel: 'Experimentar Enterprise por 5 dias grátis',
                    onTap: startingTrial ? null : onTrial,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Cancele antes do vencimento para evitar cobrança.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: mute),
                    ),
                  ),
                ],
                if (trialUsed) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? EagleTokens.darkCardHi
                              : TokensStrip.borderDefault,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 15, color: mute),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Período gratuito já utilizado. A cobrança começa imediatamente ao assinar.',
                            style: TextStyle(
                              color: mute,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'Assinar Enterprise',
                    semanticsLabel: 'Assinar plano Enterprise',
                    onTap: onAssinar,
                  ),
                ],
              ],

              if (isCurrent) ...[
                const SizedBox(height: TokensStrip.s4),
                Semantics(
                  button: true,
                  label: 'Gerenciar assinatura Enterprise',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAssinar,
                      icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                      label: const Text('Gerenciar assinatura'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: const BorderSide(color: _accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final bool included;
  const _Feature(this.label, {required this.included});
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  final Color accent;
  final bool isDark;

  const _FeatureRow({
    required this.feature,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final excludedInk =
        isDark
            ? EagleTokens.darkInkMute
            : ink.withValues(alpha: 0.62);
    final excludedBorder =
        isDark
            ? EagleTokens.darkLine
            : ink.withValues(alpha: 0.14);

    return Semantics(
      label:
          feature.included
              ? 'Inclui ${feature.label}'
              : 'Não inclui ${feature.label}',
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:
              feature.included
                  ? (isDark
                      ? EagleTokens.goodSoft.withValues(alpha: 0.15)
                      : EagleTokens.goodSoft)
                  : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
          borderRadius: BorderRadius.circular(10),
          border:
              feature.included
                  ? null
                  : Border.all(color: excludedBorder),
        ),
        child: Row(
          children: [
            Icon(
              feature.included ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: feature.included ? EagleTokens.good : excludedInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                feature.label,
                style: TextStyle(
                  fontSize: 13,
                  color: feature.included ? ink : excludedInk,
                  fontWeight: feature.included ? FontWeight.w600 : FontWeight.w500,
                  decoration:
                      feature.included ? null : TextDecoration.lineThrough,
                  decorationColor: excludedInk.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PlanBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Plano atual',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.semanticsLabel,
    this.loadingLabel,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null && !loading,
      label: loading ? (loadingLabel ?? label) : semanticsLabel,
      child: FxLiquidPrimaryButton(
        label: label,
        loadingLabel: loadingLabel,
        loading: loading,
        onPressed: onTap,
      ),
    );
  }
}

class _TrialInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TrialInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: EagleTokens.good),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: EagleTokens.good,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

String _fmtDate(DateTime v) =>
    '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
