import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trial Enterprise ativado. Você já pode usar os recursos avançados.',
          ),
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Erro ao ativar trial: $error');
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;
    final trialEndsAt = perfil?.trialEndsAt;
    final trialAtivo =
        trialEndsAt != null && trialEndsAt.isAfter(DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Planos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Text(
              'Escolha o plano ideal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Monte a operação do seu negócio no ritmo certo e faça o upgrade quando fizer sentido.',
              style: TextStyle(color: mute, height: 1.45),
            ),

            // ── Trial ativo banner ───────────────────────────────────────
            if (trialAtivo) ...[
              const SizedBox(height: 16),
              _TrialActiveBanner(endsAt: trialEndsAt),
            ],

            const SizedBox(height: 24),

            // ── FREE ────────────────────────────────────────────────────
            _PlanCard(
              isDark: isDark,
              name: 'FREE',
              price: 'Grátis',
              accentColor:
                  isDark ? EagleTokens.darkInkMute : const Color(0xFF6B7280),
              isCurrent: currentPlan == SubscriptionPlan.FREE,
              features: const [
                _Feature('Até 5 alunos', included: true),
                _Feature('Treinos e agenda básicos', included: true),
                _Feature('IA avançada', included: false),
                _Feature('Financeiro e CRM', included: false),
                _Feature('White-label', included: false),
                _Feature('Landing page', included: false),
              ],
              cta:
                  currentPlan == SubscriptionPlan.FREE
                      ? null // já está no plano
                      : null, // downgrade não é feito aqui
              ctaLabel:
                  currentPlan == SubscriptionPlan.FREE ? 'Plano atual' : null,
            ),

            const SizedBox(height: 16),

            // ── PREMIUM ─────────────────────────────────────────────────
            _PlanCard(
              isDark: isDark,
              name: 'PREMIUM',
              price: 'R\$ 79,00/mês',
              accentColor: primary,
              isCurrent: currentPlan == SubscriptionPlan.PREMIUM,
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
                _Feature('Landing page Focux', included: true),
                _Feature('White-label', included: false),
                _Feature('IA ilimitada + RAG', included: false),
              ],
              cta:
                  currentPlan != SubscriptionPlan.PREMIUM &&
                          currentPlan.level < SubscriptionPlan.PREMIUM.level
                      ? _PrimaryButton(
                        label: 'Assinar Premium',
                        onTap:
                            () => context.push(
                              '/assinatura',
                              extra: SubscriptionPlan.PREMIUM.apiName,
                            ),
                      )
                      : null,
              ctaLabel:
                  currentPlan == SubscriptionPlan.PREMIUM
                      ? 'Plano atual'
                      : null,
            ),

            const SizedBox(height: 16),

            // ── ENTERPRISE ──────────────────────────────────────────────
            _EnterpriseCard(
              isDark: isDark,
              isCurrent: currentPlan == SubscriptionPlan.ENTERPRISE,
              trialUsed: trialUsed,
              trialAtivo: trialAtivo,
              startingTrial: _startingTrial,
              onTrial: _startTrial,
              onAssinar:
                  () => context.push(
                    '/assinatura',
                    extra: SubscriptionPlan.ENTERPRISE.apiName,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trial Active Banner ─────────────────────────────────────────────────────

class _TrialActiveBanner extends StatelessWidget {
  final DateTime endsAt;
  const _TrialActiveBanner({required this.endsAt});

  @override
  Widget build(BuildContext context) {
    final remaining = endsAt.difference(DateTime.now()).inDays;
    return Container(
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
    );
  }
}

// ─── Plan Card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final bool isDark;
  final String name, price;
  final Color accentColor;
  final bool isCurrent;
  final List<_Feature> features;
  final Widget? cta;
  final String? ctaLabel;
  final _PlanBadge? badge;

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
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? accentColor : line,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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

          // Feature list
          ...features.map(
            (f) => _FeatureRow(feature: f, accent: accentColor, mute: mute),
          ),

          // CTA
          if (cta != null) ...[const SizedBox(height: 16), cta!],
          if (ctaLabel != null && cta == null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                ctaLabel!,
                style: TextStyle(
                  color: mute,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Enterprise Card (especializado) ─────────────────────────────────────────

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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
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
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent ? _accent : line,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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

            // Features
            ...[
              const _Feature('Alunos ilimitados', included: true),
              const _Feature('IA ilimitada + RAG', included: true),
              const _Feature('White-label completo', included: true),
              const _Feature('Domínio customizado', included: true),
              const _Feature('Landing page + prova social', included: true),
              const _Feature('Suporte prioritário', included: true),
            ].map((f) => _FeatureRow(feature: f, accent: _accent, mute: mute)),

            // CTA section
            if (!isCurrent) ...[
              const SizedBox(height: 20),

              // Trial disponível
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
                  label:
                      startingTrial
                          ? 'Ativando...'
                          : 'Experimentar 5 dias grátis',
                  loading: startingTrial,
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

              // Trial já usado → assinar direto
              if (trialUsed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                            ? EagleTokens.darkCardHi
                            : EagleTokens.lineSoft),
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
                _PrimaryButton(label: 'Assinar Enterprise', onTap: onAssinar),
              ],
            ],

            // Plano atual → gerenciar
            if (isCurrent) ...[
              const SizedBox(height: 16),
              SizedBox(
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
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Feature {
  final String label;
  final bool included;
  const _Feature(this.label, {required this.included});
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  final Color accent, mute;
  const _FeatureRow({
    required this.feature,
    required this.accent,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:
            feature.included
                ? (isDark
                    ? EagleTokens.goodSoft.withValues(alpha: 0.15)
                    : EagleTokens.goodSoft)
                : (isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            feature.included ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: feature.included ? EagleTokens.good : mute,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature.label,
              style: TextStyle(
                fontSize: 13,
                color: feature.included ? null : mute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
    return Container(
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
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor: EagleTokens.darkCardHi,
          disabledForegroundColor: EagleTokens.darkInkMute,
        ),
        child:
            loading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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

// ─── Utils ────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime v) =>
    '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
