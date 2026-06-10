part of 'paywall_components.dart';

class PaywallPlanFeatureSections extends StatelessWidget {
  final List<PaywallPlanFeatureSection> sections;
  final Color accent;
  final Color ink;
  final Color mute;
  final VoidCallback? onFeatureHelp;
  final bool allowLockedTap;
  final bool showLegend;
  final bool hideLockedOnlySections;

  const PaywallPlanFeatureSections({
    super.key,
    required this.sections,
    required this.accent,
    required this.ink,
    required this.mute,
    this.onFeatureHelp,
    this.allowLockedTap = true,
    this.showLegend = false,
    this.hideLockedOnlySections = false,
  });

  List<PaywallPlanFeatureSection> get _visibleSections {
    if (!hideLockedOnlySections) return sections;
    return sections
        .where(
          (section) =>
              section.items.any((item) => item.included || item.comingSoon),
        )
        .toList();
  }

  Duration _expansionDuration(BuildContext context) =>
      TokensStrip.prefersReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 220);

  PaywallFeatureEducation _education(PaywallPlanFeatureItem item) {
    return PaywallFeatureEducation(
      row: PaywallFeatureRow(
        label: item.label,
        included: item.included,
        highlight: item.highlight,
        comingSoon: item.comingSoon,
      ),
      education: PaywallCatalog.educationByLabel[item.label],
      capability: item.capability,
      upgradePlan: item.upgradePlan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = _visibleSections;
    final comingSoonItems = <PaywallPlanFeatureItem>[
      for (final section in visibleSections)
        for (final item in section.items)
          if (item.comingSoon) item,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in visibleSections) ...[
            if (section.collapsible)
              Theme(
                data: PaywallTierChrome.expansionTheme(context, accent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: _PlanSectionTitle(
                    title: section.title,
                    accent: accent,
                    mute: mute,
                    ink: ink,
                  ),
                  initiallyExpanded: section.initiallyExpanded,
                  expansionAnimationStyle: AnimationStyle(
                    duration: _expansionDuration(context),
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                  children:
                      section.items
                          .where((item) => !item.comingSoon)
                          .map(
                            (item) => PaywallFeatureLine(
                              feature: _education(item),
                              accent: accent,
                              mute: mute,
                              ink: ink,
                              onHelp: onFeatureHelp,
                              allowLockedTap: allowLockedTap,
                            ),
                          )
                          .toList(),
                ),
              )
            else ...[
              _PlanSectionTitle(
                title: section.title,
                accent: accent,
                mute: mute,
                ink: ink,
              ),
              ...section.items
                  .where((item) => !item.comingSoon)
                  .map(
                    (item) => PaywallFeatureLine(
                      feature: _education(item),
                      accent: accent,
                      mute: mute,
                      ink: ink,
                      onHelp: onFeatureHelp,
                      allowLockedTap: allowLockedTap,
                    ),
                  ),
            ],
            const SizedBox(height: 4),
          ],
          if (comingSoonItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PlanSectionTitle(
              title: 'Em breve',
              accent: PaywallCatalog.warning,
              mute: mute,
              ink: ink,
            ),
            ...comingSoonItems.map(
              (item) => PaywallFeatureLine(
                feature: _education(item),
                accent: accent,
                mute: mute,
                ink: ink,
                onHelp: onFeatureHelp,
                allowLockedTap: allowLockedTap,
              ),
            ),
          ],
          if (showLegend) ...[
            const SizedBox(height: 10),
            _PaywallFeatureLegend(ink: ink, mute: mute),
          ],
        ],
      ),
    );
  }
}

/// Legenda compacta — ícone + texto (sem depender só de cor).
class _PaywallFeatureLegend extends StatelessWidget {
  final Color ink;
  final Color mute;

  const _PaywallFeatureLegend({required this.ink, required this.mute});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      height: 1.35,
      color: mute.withValues(alpha: 0.88),
    );
    return Semantics(
      label:
          'Legenda: check verde incluído no plano; cadeado requer upgrade; '
          'ícone destaque do plano; badge PRO indica Enterprise Pro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaywallLegendRow(
            icon: Icons.check_circle_rounded,
            iconColor: PaywallCatalog.green,
            label: 'Incluído no seu plano',
            style: style,
          ),
          const SizedBox(height: 4),
          _PaywallLegendRow(
            icon: Icons.lock_rounded,
            iconColor: mute.withValues(alpha: 0.72),
            label: 'Toque para ver upgrade',
            style: style,
          ),
          const SizedBox(height: 4),
          _PaywallLegendRow(
            icon: Icons.auto_awesome_rounded,
            iconColor: PaywallCatalog.brandDeep,
            label: 'Destaque do plano',
            style: style,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _PlanChip(label: 'PRO', color: PaywallCatalog.brandDeep),
              const SizedBox(width: 6),
              Expanded(child: Text('Requer Enterprise Pro', style: style)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaywallLegendRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextStyle style;

  const _PaywallLegendRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}

/// ROI compacto — assinante Enterprise vendo o plano atual (upgrade para Pro).
class PaywallEnterpriseProRoiCard extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final double? monthlyDelta;
  final VoidCallback? onExplorePro;

  const PaywallEnterpriseProRoiCard({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.monthlyDelta,
    this.onExplorePro,
  });

  static const _bullets = <({String text, IconData icon})>[
    (
      text: 'Landing, Loja digital e Pose Coach no seu app',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      text: 'Economize agência e desenvolvimento sob medida',
      icon: Icons.savings_outlined,
    ),
    (
      text: 'Escale alunos sem refazer infraestrutura',
      icon: Icons.trending_up_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(
      SubscriptionPlan.ENTERPRISE_PRO,
    );
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final delta = monthlyDelta;
    final deltaLabel =
        delta != null && delta > 0
            ? '+R\$ ${delta.toStringAsFixed(0)}/mês'
            : null;

    return PaywallGlassCard(
      margin: EdgeInsets.zero,
      accent: accent,
      glow: false,
      blur: false,
      elevationLevel: 6,
      padding: const EdgeInsets.all(14),
      child: PaywallInsetPanel(
        accent: accent,
        isDark: isDark,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 22, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por que o Enterprise Pro?',
                    style: AppTypography.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.25,
                      color: ink,
                    ),
                  ),
                ),
                if (deltaLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.green.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(TokensStrip.rPill),
                      border: Border.all(
                        color: PaywallCatalog.green.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      deltaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PaywallCatalog.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final bullet in _bullets) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(bullet.icon, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet.text,
                        style: TokensStrip.body(
                          color: secondary,
                        ).copyWith(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onExplorePro != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onExplorePro!();
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: accent,
                  ),
                  label: Text(
                    'Ver Enterprise Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PaywallCatalog.readableTierAccent(
                        accent,
                        isDark: isDark,
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

/// Convite discreto para explorar o tier Pro no Plan Studio.
