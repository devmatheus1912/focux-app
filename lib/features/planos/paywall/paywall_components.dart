import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../assinatura/data/assinatura_repository.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../../subscription/subscription_products.dart';
import 'paywall_catalog.dart';

// ─── Hero ───────────────────────────────────────────────────────────────────

class PaywallHero extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isDark;

  const PaywallHero({
    super.key,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.1,
          colors: [
            primary.withValues(alpha: isDark ? 0.14 : 0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '⚡ FOCUX · PLANOS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ink, primary],
            ).createShader(bounds),
            child: Text(
              'Seu app. Sua marca.\nSeus alunos. Sem limite.',
              textAlign: TextAlign.center,
              style: TokensStrip.h1(color: Colors.white).copyWith(
                fontSize: 30,
                height: 1.06,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cada recurso aqui responde: isso me ajuda a ganhar mais ou trabalhar menos?',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── Context banner ─────────────────────────────────────────────────────────

class PaywallContextBanner extends StatelessWidget {
  final PlanoUsageSnapshot usage;
  final String? blockedFeatureLabel;
  final Color ink;
  final Color mute;
  final VoidCallback? onCta;

  const PaywallContextBanner({
    super.key,
    required this.usage,
    this.blockedFeatureLabel,
    required this.ink,
    required this.mute,
    this.onCta,
  });

  String? _message() {
    if (blockedFeatureLabel != null && blockedFeatureLabel!.isNotEmpty) {
      final target = PlanEntitlements.targetPlan(capability: null);
      return 'Você tentou usar $blockedFeatureLabel. '
          'Disponível no plano ${target.apiName}.';
    }
    if (usage.alunosAtLimit && usage.limiteAlunos != null) {
      return 'Você atingiu ${usage.limiteAlunos} alunos. '
          'Cada novo = R\$ 300–600/mês. Enterprise remove o teto.';
    }
    if (usage.alunosNearLimit && usage.limiteAlunos != null) {
      final left = (usage.limiteAlunos! - usage.alunosAtivos).clamp(0, 99);
      return 'Você tem ${usage.alunosAtivos} alunos — faltam $left para o limite. '
          'Upgrade libera mais vagas e receita.';
    }
    if (usage.iaAtLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} IA este mês. '
          'Enterprise libera até 400+ interações.';
    }
    if (usage.iaNearLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} interações de IA. '
          'Enterprise dá mais folga no Copiloto.';
    }
    if (usage.plano == SubscriptionPlan.FREE) {
      return 'Com 20 alunos a R\$ 400 = R\$ 8.000/mês. '
          'O Premium representa menos de 1% desse faturamento.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final msg = _message();
    if (msg == null) return const SizedBox.shrink();

    final target = PlanEntitlements.softGateTargetPlan(usage) ??
        SubscriptionPlan.PREMIUM;
    final accent = PaywallCatalog.accentForPlan(target);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TokensStrip.body(color: ink)),
          ),
          if (onCta != null)
            TextButton(
              onPressed: onCta,
              child: Text('Ver ${target.apiName}', style: TextStyle(color: accent)),
            ),
        ],
      ),
    );
  }
}

// ─── Social proof + ROI strip ─────────────────────────────────────────────────

class PaywallSocialProofStrip extends StatelessWidget {
  final Color line;
  final Color ink;
  final Color mute;
  final List<({String value, String label})> socialProof;

  const PaywallSocialProofStrip({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
    List<({String value, String label})>? socialProof,
  }) : socialProof = socialProof ?? PaywallCatalog.socialProof;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < socialProof.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, color: line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                child: Column(
                  children: [
                    Text(
                      socialProof[i].value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      socialProof[i].label,
                      textAlign: TextAlign.center,
                      style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaywallRoiStrip extends StatelessWidget {
  final Color line;

  const PaywallRoiStrip({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          if (narrow) {
            return Column(
              children: [
                for (var i = 0; i < PaywallCatalog.roiStrip.length; i++)
                  _RoiCell(
                    item: PaywallCatalog.roiStrip[i],
                    line: line,
                    showBottom: i < PaywallCatalog.roiStrip.length - 1,
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var i = 0; i < PaywallCatalog.roiStrip.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, color: line),
                Expanded(child: _RoiCell(item: PaywallCatalog.roiStrip[i], line: line)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoiCell extends StatelessWidget {
  final ({String value, String label, Color color}) item;
  final Color line;
  final bool showBottom;

  const _RoiCell({
    required this.item,
    required this.line,
    this.showBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: showBottom
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: line)),
            )
          : null,
      child: Column(
        children: [
          Text(
            item.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: item.color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: EagleTokens.darkInkMute),
          ),
        ],
      ),
    );
  }
}

// ─── Rich plan card ───────────────────────────────────────────────────────────

class PaywallRichPlanCard extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrent;
  final String monthlyPrice;
  final String annualPrice;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onFeatureHelp;

  const PaywallRichPlanCard({
    super.key,
    required this.plano,
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onTap,
    this.onFeatureHelp,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final badge = PaywallCatalog.badgeForPlan(plan);
    final features = PaywallCatalog.featuresForPlan(plano, plan).take(5);
    final motion = TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Plano ${plan.apiName}, $monthlyPrice mensal, $annualPrice anual',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.55)
                  : line.withValues(alpha: 0.6),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected && plan != SubscriptionPlan.FREE
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 40,
                    ),
                  ]
                : null,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.04 : 0.9),
                isDark ? EagleTokens.darkCard : EagleTokens.card,
              ],
            ),
          ),
          child: Stack(
            children: [
              if (badge != null && !isCurrent)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _PlanChip(label: badge, color: accent),
                ),
              if (isCurrent)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _PlanChip(label: 'SEU PLANO', color: accent),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.apiName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PaywallCatalog.subtitleForPlan(plan),
                      style: TokensStrip.bodyMuted(color: mute),
                    ),
                    const SizedBox(height: 12),
                    if (!isCurrent && plan != SubscriptionPlan.FREE)
                      Row(
                        children: [
                          Expanded(
                            child: _PriceBox(
                              label: 'Mensal',
                              price: monthlyPrice,
                              mute: mute,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PriceBox(
                              label: 'Anual',
                              price: annualPrice,
                              mute: mute,
                              highlight: true,
                            ),
                          ),
                        ],
                      )
                    else if (isCurrent)
                      Text(
                        'Ativo',
                        style: TokensStrip.h2(color: ink).copyWith(fontSize: 22),
                      )
                    else
                      Text(
                        'R\$ 0',
                        style: TokensStrip.h2(color: ink).copyWith(fontSize: 22),
                      ),
                    if (PaywallCatalog.roiTagForPlan(plan) != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: PaywallCatalog.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: PaywallCatalog.green.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          PaywallCatalog.roiTagForPlan(plan)!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: PaywallCatalog.green,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      PaywallCatalog.descriptionForPlan(plan),
                      style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...features.map(
                      (f) => PaywallFeatureLine(
                        feature: f,
                        accent: accent,
                        mute: mute,
                        ink: ink,
                        onHelp: onFeatureHelp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String price;
  final Color mute;
  final bool highlight;

  const _PriceBox({
    required this.label,
    required this.price,
    required this.mute,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: highlight ? 0.14 : 0.08),
        ),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PlanChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.38)),
        color: color.withValues(alpha: 0.13),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class PaywallFeatureLine extends StatelessWidget {
  final PaywallFeatureEducation feature;
  final Color accent;
  final Color mute;
  final Color ink;
  final VoidCallback? onHelp;

  const PaywallFeatureLine({
    super.key,
    required this.feature,
    required this.accent,
    required this.mute,
    required this.ink,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    final row = feature.row;
    final off = !row.included;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            row.included ? '✓' : '—',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: row.included ? PaywallCatalog.green : mute,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w500,
                color: off ? mute.withValues(alpha: 0.42) : ink,
                decoration: off ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (row.highlight) Text('★', style: TextStyle(color: accent, fontSize: 12)),
          if (feature.education != null && onHelp != null)
            Semantics(
              button: true,
              label: 'Saiba mais sobre ${row.label}',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.help_outline_rounded, size: 18, color: mute),
                onPressed: () => showPaywallFeatureEducation(context, feature.education!),
              ),
            ),
        ],
      ),
    );
  }
}

void showPaywallFeatureEducation(
  BuildContext context,
  PaywallEducationContent content,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: EagleTokens.darkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scroll,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EagleTokens.darkLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content.title,
                style: TokensStrip.h2(color: EagleTokens.darkInk),
              ),
              const SizedBox(height: 16),
              Text('O que é', style: TextStyle(color: PaywallCatalog.brand, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(content.whatIs, style: TokensStrip.body(color: EagleTokens.darkInkMute)),
              const SizedBox(height: 14),
              Text(
                'Por que importa pra você',
                style: TextStyle(color: PaywallCatalog.brand, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(content.whyMatters, style: TokensStrip.body(color: EagleTokens.darkInkMute)),
              if (content.roiStatement != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaywallCatalog.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PaywallCatalog.green.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    content.roiStatement!,
                    style: const TextStyle(
                      color: PaywallCatalog.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text('Disponível em', style: TextStyle(color: PaywallCatalog.brand, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: content.plans
                    .map((p) => _PlanChip(label: p, color: PaywallCatalog.accentForPlan(
                      subscriptionPlanFromApi(p),
                    )))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ─── ROI calculator ─────────────────────────────────────────────────────────

class PaywallRoiCalculator extends StatefulWidget {
  final List<Plano> paidPlans;
  final Color ink;
  final Color mute;
  final Color line;
  final ValueChanged<SubscriptionPlan>? onSuggestPlan;

  const PaywallRoiCalculator({
    super.key,
    required this.paidPlans,
    required this.ink,
    required this.mute,
    required this.line,
    this.onSuggestPlan,
  });

  @override
  State<PaywallRoiCalculator> createState() => _PaywallRoiCalculatorState();
}

class _PaywallRoiCalculatorState extends State<PaywallRoiCalculator> {
  bool _expanded = false;
  int _students = 12;
  double _monthlyFee = 400;

  @override
  Widget build(BuildContext context) {
    final mrr = _students * _monthlyFee;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: widget.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Calculadora de ROI, ${_expanded ? 'recolher' : 'expandir'}',
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🧮', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calcule seu ROI', style: TokensStrip.h2(color: widget.ink).copyWith(fontSize: 17)),
                          Text(
                            'Veja qual plano faz sentido agora',
                            style: TokensStrip.bodyMuted(color: widget.mute),
                          ),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: widget.mute),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alunos ativos hoje', style: TokensStrip.bodyMuted(color: widget.mute)),
                  Slider(
                    value: _students.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: '$_students',
                    onChanged: (v) => setState(() => _students = v.round()),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mensalidade média (R\$)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    controller: TextEditingController(text: _monthlyFee.toStringAsFixed(0)),
                    onChanged: (v) {
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n != null) setState(() => _monthlyFee = n.clamp(50, 5000));
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seu MRR atual', style: TokensStrip.bodyMuted(color: widget.mute)),
                        Text(
                          'R\$ ${mrr.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: widget.ink,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.paidPlans.map((p) {
                    final plan = subscriptionPlanFromApi(p.nome);
                    final price = p.precoMensal;
                    final pct = mrr > 0 ? (price / mrr * 100) : 0.0;
                    final payback = price > 0 ? (price / _monthlyFee).ceil() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${plan.apiName} · R\$ ${price.toStringAsFixed(2)}/mês',
                              style: TokensStrip.body(color: widget.ink),
                            ),
                          ),
                          Text(
                            mrr > 0 ? '${pct.toStringAsFixed(1)}% MRR' : '—',
                            style: TextStyle(
                              color: PaywallCatalog.accentForPlan(plan),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            payback <= 1 ? '1 aluno paga' : '$payback alunos',
                            style: TokensStrip.bodyMuted(color: widget.mute).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (mrr > 0 && widget.paidPlans.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Premium = ${(widget.paidPlans.first.precoMensal / mrr * 100).toStringAsFixed(2)}% do faturamento'
                      '${widget.paidPlans.first.precoMensal / mrr < 0.01 ? ' — menos de 1%, ROI imediato' : ''}',
                      style: TokensStrip.bodyMuted(color: widget.mute),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comparison table ─────────────────────────────────────────────────────────

class PaywallComparisonTable extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;

  const PaywallComparisonTable({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text('Comparar planos', style: TokensStrip.h2(color: ink).copyWith(fontSize: 17)),
        subtitle: Text('Tabela completa', style: TokensStrip.bodyMuted(color: mute)),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(EagleTokens.darkCardHi),
              columns: const [
                DataColumn(label: Text('Feature')),
                DataColumn(label: Text('FREE')),
                DataColumn(label: Text('PREMIUM')),
                DataColumn(label: Text('ENT.')),
              ],
              rows: PaywallCatalog.comparisonRows
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text(r.feature, style: TextStyle(color: ink, fontSize: 12))),
                        DataCell(Text(r.free, style: TextStyle(color: mute))),
                        DataCell(Text(r.premium, style: TextStyle(color: mute))),
                        DataCell(Text(r.enterprise, style: TextStyle(color: mute))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class PaywallRoiRowsList extends StatelessWidget {
  final Color ink;
  final Color mute;

  const PaywallRoiRowsList({super.key, required this.ink, required this.mute});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaywallCatalog.roiRows
          .map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EagleTokens.darkCard,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: EagleTokens.darkLine),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(r.label, style: TokensStrip.body(color: ink))),
                  Text(
                    r.value,
                    style: TextStyle(
                      color: PaywallCatalog.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PlanChip(label: r.planChip, color: r.color),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class PaywallTrustFooter extends StatelessWidget {
  final Color mute;
  final Color primary;

  const PaywallTrustFooter({super.key, required this.mute, required this.primary});

  @override
  Widget build(BuildContext context) {
    TextStyle link() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
    );
    return Column(
      children: [
        Text(
          'Sem fidelidade · Cancele quando quiser nas configurações do app',
          textAlign: TextAlign.center,
          style: TokensStrip.bodyMuted(color: mute),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            GestureDetector(
              onTap: () => FocuxLegal.openPrivacy(),
              child: Text('Privacidade (LGPD)', style: link()),
            ),
            GestureDetector(
              onTap: () => FocuxLegal.openTerms(),
              child: Text('Termos de uso', style: link()),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class PaywallLoadingSkeleton extends StatelessWidget {
  const PaywallLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = EagleTokens.darkCard;
    final highlight = EagleTokens.darkCardHi;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 56, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(22)),
            ),
        ],
      ),
    );
  }
}

String formatPaywallPriceBrl(double value) {
  if (value == 0) return 'R\$ 0';
  final whole = value == value.roundToDouble();
  return whole
      ? 'R\$ ${value.toStringAsFixed(0)}'
      : 'R\$ ${value.toStringAsFixed(2)}';
}

String paywallMonthlyFromPlano(Plano plano) => formatPaywallPriceBrl(plano.precoMensal);

String paywallAnnualMonthlyEquiv(Plano plano) {
  final annual = plano.precoAnual ?? SubscriptionProducts.referenceAnnualPrice(plano.precoMensal);
  return formatPaywallPriceBrl(annual / 12);
}
