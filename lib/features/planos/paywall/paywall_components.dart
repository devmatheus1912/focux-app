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

/// Âncoras de scroll na vitrine de planos.
enum PaywallScrollTarget { planos, features, roi, gatilhos }

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: primary),
                const SizedBox(width: 6),
                Text(
                  'FOCUX · PLANOS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: primary,
                  ),
                ),
              ],
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

class PaywallQuickNav extends StatelessWidget {
  final Color primary;
  final Color ink;
  final ValueChanged<PaywallScrollTarget> onSectionTap;

  const PaywallQuickNav({
    super.key,
    required this.primary,
    required this.ink,
    required this.onSectionTap,
  });

  static const _items = <({PaywallScrollTarget id, String label, IconData icon})>[
    (id: PaywallScrollTarget.planos, label: 'Planos', icon: Icons.view_agenda_outlined),
    (id: PaywallScrollTarget.features, label: 'Features', icon: Icons.star_outline_rounded),
    (id: PaywallScrollTarget.roi, label: 'ROI', icon: Icons.savings_outlined),
    (id: PaywallScrollTarget.gatilhos, label: 'Gatilhos', icon: Icons.bolt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Ir para ${_items[i].label}',
                child: Material(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSectionTap(_items[i].id),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_items[i].icon, size: 16, color: ink),
                          const SizedBox(width: 8),
                          Text(
                            _items[i].label,
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class PaywallSectionAnchor extends StatelessWidget {
  final GlobalKey anchorKey;
  final Widget child;

  const PaywallSectionAnchor({
    super.key,
    required this.anchorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: anchorKey, child: child);
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
  final Color ink;
  final Color mute;

  const PaywallRoiStrip({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
  });

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
          final items = PaywallCatalog.roiStrip;
          final cols = c.maxWidth < 520 ? 2 : 3;
          return Column(
            children: [
              for (var row = 0; row < (items.length / cols).ceil(); row++) ...[
                if (row > 0) Divider(height: 1, color: line),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < cols; col++) ...[
                        if (col > 0) VerticalDivider(width: 1, color: line),
                        Expanded(
                          child: row * cols + col < items.length
                              ? _RoiCell(
                                  item: items[row * cols + col],
                                  line: line,
                                  mute: mute,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
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
  final Color mute;

  const _RoiCell({
    required this.item,
    required this.line,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 11),
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
    final sections = PaywallCatalog.featureSectionsForPlan(plano, plan);
    final motion = TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Semantics(
      selected: isSelected,
      label:
          'Plano ${PaywallCatalog.displayPlanName(plan)}, $monthlyPrice mensal, $annualPrice anual',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PaywallCatalog.displayPlanName(plan),
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
                                    ink: ink,
                                    mute: mute,
                                    line: line,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _PriceBox(
                                    label: 'Anual',
                                    price: annualPrice,
                                    ink: ink,
                                    mute: mute,
                                    line: line,
                                    isDark: isDark,
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
                            _RoiMoneyTag(text: PaywallCatalog.roiTagForPlan(plan)!),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            PaywallCatalog.descriptionForPlan(plan),
                            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                PaywallPlanFeatureSections(
                  sections: sections,
                  accent: accent,
                  ink: ink,
                  mute: mute,
                  onFeatureHelp: onFeatureHelp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PaywallPlanFeatureSections extends StatelessWidget {
  final List<PaywallPlanFeatureSection> sections;
  final Color accent;
  final Color ink;
  final Color mute;
  final VoidCallback? onFeatureHelp;

  const PaywallPlanFeatureSections({
    super.key,
    required this.sections,
    required this.accent,
    required this.ink,
    required this.mute,
    this.onFeatureHelp,
  });

  PaywallFeatureEducation _education(PaywallPlanFeatureItem item) {
    return PaywallFeatureEducation(
      row: PaywallFeatureRow(
        label: item.label,
        included: item.included,
        highlight: item.highlight,
        comingSoon: item.comingSoon,
      ),
      education: PaywallCatalog.educationByLabel[item.label],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in sections) ...[
            if (section.collapsible)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: _PlanSectionTitle(title: section.title, accent: accent, mute: mute),
                  trailing: Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: mute,
                    ),
                  ),
                  initiallyExpanded: section.initiallyExpanded,
                  children: section.items
                      .map(
                        (item) => PaywallFeatureLine(
                          feature: _education(item),
                          accent: accent,
                          mute: mute,
                          ink: ink,
                          onHelp: onFeatureHelp,
                        ),
                      )
                      .toList(),
                ),
              )
            else ...[
              _PlanSectionTitle(title: section.title, accent: accent, mute: mute),
              ...section.items.map(
                (item) => PaywallFeatureLine(
                  feature: _education(item),
                  accent: accent,
                  mute: mute,
                  ink: ink,
                  onHelp: onFeatureHelp,
                ),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  final String title;
  final Color accent;
  final Color mute;

  const _PlanSectionTitle({
    required this.title,
    required this.accent,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
          color: accent,
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String price;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool highlight;

  const _PriceBox({
    required this.label,
    required this.price,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark
        ? Colors.white.withValues(alpha: highlight ? 0.08 : 0.04)
        : EagleTokens.paper;
    final borderColor = highlight
        ? PaywallCatalog.brand.withValues(alpha: 0.45)
        : line;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: highlight ? 1.4 : 1),
        color: fill,
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ink,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _RoiMoneyTag extends StatelessWidget {
  final String text;

  const _RoiMoneyTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PaywallCatalog.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: PaywallCatalog.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, size: 16, color: PaywallCatalog.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: PaywallCatalog.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color paywallChipColorForLabel(String label) => switch (label) {
  'PREMIUM' => PaywallCatalog.brand,
  'ENTERPRISE' => PaywallCatalog.gold,
  'ENT. PRO' => PaywallCatalog.purple,
  _ => PaywallCatalog.brand,
};

class PaywallSectionHeader extends StatelessWidget {
  final String title;
  final String? note;
  final Color ink;
  final Color mute;

  const PaywallSectionHeader({
    super.key,
    required this.title,
    this.note,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(title, style: TokensStrip.h2(color: ink).copyWith(fontSize: 24)),
          ),
          if (note != null)
            Text(note!, style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13)),
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
          if (row.comingSoon)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _PlanChip(label: 'EM BREVE', color: PaywallCatalog.warning),
            ),
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
  final sheetInk = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
  final sheetMute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  final sheetLine = isDark ? EagleTokens.darkLine : EagleTokens.line;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: sheetBg,
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
                    color: sheetLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content.title,
                style: TokensStrip.h2(color: sheetInk),
              ),
              const SizedBox(height: 16),
              Text('O que é', style: TextStyle(color: PaywallCatalog.brand, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(content.whatIs, style: TokensStrip.body(color: sheetMute)),
              const SizedBox(height: 14),
              Text(
                'Por que importa pra você',
                style: TextStyle(color: PaywallCatalog.brand, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(content.whyMatters, style: TokensStrip.body(color: sheetMute)),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.savings_outlined, size: 18, color: PaywallCatalog.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          content.roiStatement!,
                          style: const TextStyle(
                            color: PaywallCatalog.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                    Icon(Icons.calculate_outlined, size: 26, color: PaywallCatalog.brand),
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
                              '${PaywallCatalog.displayPlanName(plan)} · R\$ ${price.toStringAsFixed(2)}/mês',
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
  final bool isDark;

  const PaywallComparisonTable({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  TextStyle _cellStyle({bool header = false}) => TextStyle(
    color: header ? ink : mute,
    fontSize: header ? 11 : 12,
    fontWeight: header ? FontWeight.w800 : FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? EagleTokens.darkCardHi : EagleTokens.paper;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(16),
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text('Comparar planos', style: TokensStrip.h2(color: ink).copyWith(fontSize: 17)),
        subtitle: Text('Tabela completa · 4 tiers', style: TokensStrip.bodyMuted(color: mute)),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: SizedBox(
              width: 560,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(headerBg),
                columns: [
                  DataColumn(label: Text('Recurso', style: _cellStyle(header: true))),
                  DataColumn(label: Text('FREE', style: _cellStyle(header: true))),
                  DataColumn(label: Text('PREMIUM', style: _cellStyle(header: true))),
                  DataColumn(label: Text('ENTERPRISE', style: _cellStyle(header: true))),
                  DataColumn(label: Text('ENT. PRO', style: _cellStyle(header: true))),
                ],
                rows: PaywallCatalog.comparisonRows
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(Text(r.feature, style: _cellStyle())),
                          DataCell(Text(r.free, style: _cellStyle())),
                          DataCell(Text(r.premium, style: _cellStyle())),
                          DataCell(Text(r.enterprise, style: _cellStyle())),
                          DataCell(Text(r.enterprisePro, style: _cellStyle())),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaywallFeaturesGrid extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallFeaturesGrid({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in PaywallCatalog.topFeatures)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PaywallCatalog.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.icon, color: PaywallCatalog.brand, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${f.rank} ${f.title}',
                        style: TokensStrip.h2(color: ink).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      _PlanChip(label: f.badge, color: f.badgeColor),
                      const SizedBox(height: 8),
                      Text(
                        f.description,
                        style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _RoiMoneyTag(text: f.roiMoney),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: f.planChips
                            .map((p) => _PlanChip(label: p, color: paywallChipColorForLabel(p)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PaywallGatilhosList extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallGatilhosList({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      children: PaywallCatalog.upgradeTriggers.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PaywallCatalog.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PaywallCatalog.brand.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      t.number,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: PaywallCatalog.brand,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TokensStrip.body(color: ink).copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          t.transition,
                          style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaywallCatalog.brand.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PaywallCatalog.brand.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    t.message,
                    style: TokensStrip.bodyMuted(color: mute).copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: mute),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mostrar como modal in-app no momento exato.',
                        style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaywallRoiRowsList extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallRoiRowsList({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...PaywallCatalog.roiRows.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final stacked = c.maxWidth < 340;
                final value = Text(
                  r.value,
                  style: TextStyle(
                    color: PaywallCatalog.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
                final chip = _PlanChip(label: r.planChip, color: r.color);
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label, style: TokensStrip.body(color: ink)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: value),
                          chip,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(r.label, style: TokensStrip.body(color: ink)),
                    ),
                    Expanded(flex: 2, child: value),
                    const SizedBox(width: 8),
                    chip,
                  ],
                );
              },
            ),
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : EagleTokens.lineSoft;
    final highlight = isDark ? EagleTokens.darkCardHi : EagleTokens.line;
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
