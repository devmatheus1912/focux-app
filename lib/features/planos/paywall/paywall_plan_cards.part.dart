part of 'paywall_components.dart';

// ─── Rich plan card ───────────────────────────────────────────────────────────

class PaywallRichPlanCard extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrent;
  final bool isLockedDowngrade;
  /// Consulta/downgrade na loja — sem preços nem fluxo de compra (Plan Studio).
  final bool referenceOnly;
  final bool dimUnselected;
  final bool collapseFeatureDetails;
  final bool compactUpsell;
  final List<String> upsellHighlights;
  final bool billingDisabled;
  final String monthlyPrice;
  final String annualPrice;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final VoidCallback? onTap;
  final SubscriptionBillingPeriod? billingPeriod;
  final ValueChanged<SubscriptionBillingPeriod>? onBillingPeriodTap;
  final VoidCallback? onFeatureHelp;
  final bool nestedInAccordion;
  final bool embeddedInStudio;
  final bool showFeatureLegend;

  const PaywallRichPlanCard({
    super.key,
    required this.plano,
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    this.isLockedDowngrade = false,
    this.referenceOnly = false,
    this.dimUnselected = false,
    this.collapseFeatureDetails = false,
    this.compactUpsell = false,
    this.upsellHighlights = const [],
    this.billingDisabled = false,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.onTap,
    this.billingPeriod,
    this.onBillingPeriodTap,
    this.onFeatureHelp,
    this.nestedInAccordion = false,
    this.embeddedInStudio = false,
    this.showFeatureLegend = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final badge = PaywallCatalog.badgeFor(plano, plan);
    final planTitle = PaywallCatalog.displayNameFor(plano, plan);
    final planSubtitle = PaywallCatalog.subtitleFor(plano, plan);
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final roiTag = PaywallCatalog.roiTagFor(plano, plan);
    final sections = PaywallCatalog.featureSectionsForPlan(plano, plan);
    final hideUpgradePricing =
        billingDisabled && !isCurrent && plan != SubscriptionPlan.FREE;
    final showCompactBody = compactUpsell && !isCurrent;
    final referenceMode = referenceOnly || isLockedDowngrade;
    final collapseFeatures = referenceMode ||
        (collapseFeatureDetails && (isCurrent || embeddedInStudio));

    final cardBody = Stack(
          children: [
            if (!embeddedInStudio && !referenceMode && badge != null && !isCurrent)
              Positioned(
                top: TokensStrip.s4,
                right: TokensStrip.s4,
                child: PaywallTierBrandPill(
                  label: badge,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            if (!embeddedInStudio && isCurrent)
              Positioned(
                top: TokensStrip.s4,
                right: TokensStrip.s4,
                child: PaywallTierBrandPill(
                  label: 'SEU PLANO',
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(PaywallSurface.cardRadius),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        embeddedInStudio ? 16 : TokensStrip.s5,
                        embeddedInStudio ? 8 : TokensStrip.s5,
                        embeddedInStudio
                            ? 16
                            : (badge != null || isCurrent)
                            ? 100
                            : TokensStrip.s5,
                        TokensStrip.s3,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!embeddedInStudio)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PaywallTierMedallion(
                                  plan: plan,
                                  accent: accent,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: TokensStrip.s3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        planTitle.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          height: 1.1,
                                          color: PaywallCatalog.tierAccentOnSurface(
                                            plan,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: TokensStrip.s1),
                                      Text(
                                        planSubtitle,
                                        style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                          fontSize: TokensStrip.fontBodySm,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else if (!isCurrent) ...[
                            Text(
                              planTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                height: 1.1,
                                color: PaywallCatalog.tierAccentOnSurface(
                                  plan,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s1),
                            Text(
                              planSubtitle,
                              style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                fontSize: TokensStrip.fontBodySm,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (!embeddedInStudio || !isCurrent)
                            const SizedBox(height: TokensStrip.s3),
                          if (referenceMode)
                            _PlanReferenceStoreHint(
                              plan: plan,
                              ink: ink,
                              mute: mute,
                              isDark: isDark,
                              accent: accent,
                            )
                          else if (!isCurrent && plan != SubscriptionPlan.FREE)
                            hideUpgradePricing && !embeddedInStudio
                                ? _StoreBillingHint(
                                    ink: ink,
                                    mute: mute,
                                    isDark: isDark,
                                  )
                                : !hideUpgradePricing
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PriceBox(
                                        label: 'Mensal',
                                        price: monthlyPrice,
                                        accent: accent,
                                        ink: ink,
                                        mute: mute,
                                        line: line,
                                        isDark: isDark,
                                        disabled: billingDisabled,
                                        selected:
                                            !billingDisabled &&
                                            isSelected &&
                                            billingPeriod ==
                                                SubscriptionBillingPeriod.monthly,
                                        onTap:
                                            billingDisabled
                                                ? null
                                                : onBillingPeriodTap == null
                                                ? null
                                                : () => onBillingPeriodTap!(
                                                      SubscriptionBillingPeriod.monthly,
                                                    ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _PriceBox(
                                        label: 'Anual',
                                        price: annualPrice,
                                        accent: accent,
                                        ink: ink,
                                        mute: mute,
                                        line: line,
                                        isDark: isDark,
                                        disabled: billingDisabled,
                                        selected:
                                            !billingDisabled &&
                                            isSelected &&
                                            (billingPeriod ??
                                                    SubscriptionBillingPeriod.yearly) ==
                                                SubscriptionBillingPeriod.yearly,
                                        onTap:
                                            billingDisabled
                                                ? null
                                                : onBillingPeriodTap == null
                                                ? null
                                                : () => onBillingPeriodTap!(
                                                      SubscriptionBillingPeriod.yearly,
                                                    ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                                : const SizedBox.shrink()
                          else if (isCurrent)
                            embeddedInStudio
                                ? _StudioActiveStatusBanner(
                                    ink: ink,
                                    mute: mute,
                                    accent: accent,
                                    isDark: isDark,
                                  )
                                : Text(
                                    'Ativo',
                                    style: AppTypography.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 26,
                                      letterSpacing: -0.4,
                                      height: 1.05,
                                      color: ink,
                                    ),
                                  )
                          else if (plan == SubscriptionPlan.FREE)
                            Text(
                              'R\$ 0',
                              style: TokensStrip.h2(color: ink).copyWith(fontSize: 22),
                            ),
                          if (roiTag != null && !referenceMode) ...[
                            const SizedBox(height: 10),
                            _RoiMoneyTag(text: roiTag),
                          ],
                          if (!embeddedInStudio &&
                              !collapseFeatures &&
                              !showCompactBody &&
                              !referenceMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              PaywallCatalog.descriptionForPlan(plan),
                              style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (showCompactBody && upsellHighlights.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            PaywallInsetPanel(
                              accent: accent,
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final line in upsellHighlights)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: accent,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: TokensStrip.body(color: ink).copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    'Detalhes no comparativo abaixo.',
                                    style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showCompactBody)
                  const SizedBox(height: 12)
                else ...[
                  Divider(height: 1, color: line.withValues(alpha: isDark ? 0.35 : 0.45)),
                  if (embeddedInStudio && collapseFeatures && isCurrent) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _PaywallStudioFeatureSummary(
                        sections: sections,
                        accent: accent,
                        ink: ink,
                        mute: mute,
                        isDark: isDark,
                      ),
                    ),
                  ],
                  if (collapseFeatures)
                    Theme(
                      data: PaywallTierChrome.expansionTheme(context, accent),
                      child: Semantics(
                        label: referenceMode
                            ? 'Ver recursos deste plano, referência'
                            : 'Ver todos os recursos do plano',
                        child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        title: Text(
                          referenceMode
                              ? 'Ver recursos deste plano (referência)'
                              : 'Ver todos os recursos',
                          style: TokensStrip.body(color: ink).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          PaywallPlanFeatureSections(
                            sections: sections,
                            accent: accent,
                            ink: ink,
                            mute: mute,
                            onFeatureHelp: onFeatureHelp,
                            allowLockedTap: !referenceMode,
                            showLegend: showFeatureLegend,
                            hideLockedOnlySections:
                                embeddedInStudio && collapseFeatures && isCurrent,
                          ),
                        ],
                      ),
                      ),
                    )
                  else
                    PaywallPlanFeatureSections(
                      sections: sections,
                      accent: accent,
                      ink: ink,
                      mute: mute,
                      onFeatureHelp: onFeatureHelp,
                      allowLockedTap: !referenceMode,
                      showLegend: showFeatureLegend,
                      hideLockedOnlySections:
                          embeddedInStudio && collapseFeatures && isCurrent,
                    ),
                ],
              ],
            ),
          ],
        );

    return Semantics(
      selected: isSelected,
      label: referenceMode
          ? 'Plano $planTitle, referência, alteração somente na ${subscriptionChannelLabel()}'
          : 'Plano $planTitle, $monthlyPrice mensal, $annualPrice anual'
              '${isCurrent ? ', plano atual' : ''}'
              '${isLockedDowngrade ? ', downgrade pela loja' : ''}',
      child: Opacity(
        opacity: referenceMode
            ? 1
            : isLockedDowngrade
            ? 0.72
            : dimUnselected
            ? (compactUpsell ? 0.92 : 0.72)
            : 1,
        child: embeddedInStudio || referenceMode
            ? cardBody
            : PaywallTierCard(
                plan: plan,
                isDark: isDark,
                isCurrent: isCurrent,
                isSelected: isSelected && plan != SubscriptionPlan.FREE,
                nestedInAccordion: nestedInAccordion,
                child: cardBody,
              ),
      ),
    );
  }
}

/// Três destaques do plano ativo — modo resumo no Plan Studio.
class _PaywallStudioFeatureSummary extends StatelessWidget {
  final List<PaywallPlanFeatureSection> sections;
  final Color accent;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _PaywallStudioFeatureSummary({
    required this.sections,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  List<PaywallPlanFeatureItem> get _highlights {
    final included = <PaywallPlanFeatureItem>[];
    for (final section in sections) {
      for (final item in section.items) {
        if (item.included && !item.comingSoon) included.add(item);
      }
    }
    included.sort((a, b) {
      final ah = a.highlight ? 1 : 0;
      final bh = b.highlight ? 1 : 0;
      return bh.compareTo(ah);
    });
    return included.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _highlights;
    if (items.isEmpty) return const SizedBox.shrink();
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Incluído no seu plano',
            style: AppTypography.inter(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: PaywallCatalog.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PaywallFeatureLabel(
                      raw: item.label,
                      ink: ink,
                      accent: accent,
                      style: TokensStrip.body(color: secondary).copyWith(
                        fontSize: 12.5,
                        fontWeight: item.highlight ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
          (section) => section.items.any(
            (item) => item.included || item.comingSoon,
          ),
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
                  children: section.items
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
              ...section.items.where((item) => !item.comingSoon).map(
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
    final style = TextStyle(fontSize: 11, height: 1.35, color: mute.withValues(alpha: 0.88));
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
    final accent = PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO);
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final delta = monthlyDelta;
    final deltaLabel = delta != null && delta > 0
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.green.withValues(alpha: isDark ? 0.18 : 0.12),
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
                        style: TokensStrip.body(color: secondary).copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
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
                  icon: Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                  label: Text(
                    'Ver Enterprise Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PaywallCatalog.readableTierAccent(accent, isDark: isDark),
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
class PaywallProExploreStrip extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final VoidCallback onExplorePro;
  final String? roiTag;

  const PaywallProExploreStrip({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.onExplorePro,
    this.roiTag,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.brandDeep;
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final tag = roiTag?.trim();
    final proAccent = PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO);
    return Semantics(
      button: true,
      label:
          'Landing, Loja digital e Pose Coach estão no Enterprise Pro. '
          '${tag != null && tag.isNotEmpty ? '$tag. ' : ''}'
          'Toque para ver o plano Pro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onExplorePro();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        proAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                        accent.withValues(alpha: isDark ? 0.06 : 0.03),
                      ],
                    ),
                  ),
                ),
              ),
              PaywallInsetPanel(
            accent: accent,
            isDark: isDark,
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Landing, Loja e Pose Coach estão no Enterprise Pro',
                    style: TokensStrip.body(color: secondary).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tag != null && tag.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.green.withValues(alpha: isDark ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(TokensStrip.rPill),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: PaywallCatalog.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.chevron_right_rounded, color: accent, size: 22),
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

class _PlanSectionTitle extends StatelessWidget {
  final String title;
  final Color accent;
  final Color mute;
  final Color ink;

  const _PlanSectionTitle({
    required this.title,
    required this.accent,
    required this.mute,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s3, bottom: TokensStrip.s2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: PaywallCatalog.readableTierAccent(accent, isDark: isDark)
                  .withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1.25,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String price;
  final Color accent;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _PriceBox({
    required this.label,
    required this.price,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = selected && !disabled;
    final textInk = disabled ? mute.withValues(alpha: 0.55) : ink;

    final box = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: FxGlassSurface(
        accent: accent,
        glow: effectiveSelected,
        blur: false,
        radius: TokensStrip.rSm,
        elevationLevel: effectiveSelected ? 8 : 3,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: mute,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textInk,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null || disabled) return box;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

/// Downgrade / plano gratuito — só consulta; mudança de tier na loja.
class _PlanReferenceStoreHint extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color ink;
  final Color mute;
  final Color accent;
  final bool isDark;

  const _PlanReferenceStoreHint({
    required this.plan,
    required this.ink,
    required this.mute,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final channel = subscriptionChannelLabel();
    final headline = plan == SubscriptionPlan.FREE
        ? 'Plano gratuito · referência'
        : 'Alteração só na $channel';
    final body = plan == SubscriptionPlan.FREE
        ? 'Compare limites com seu plano atual. Para voltar ao gratuito, use as assinaturas do dispositivo.'
        : 'Downgrade e cancelamento só na loja do dispositivo. '
            'Em Assinaturas, escolha o tier desejado.';

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            plan == SubscriptionPlan.FREE
                ? Icons.info_outline
                : Icons.storefront_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  softWrap: true,
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Introdução do accordion «Outros planos» no Plan Studio.
class PaywallOtherPlansIntro extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;

  const PaywallOtherPlansIntro({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Text(
        'Planos abaixo são só para consulta. Seu plano ativo continua no card acima.',
        style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
      ),
    );
  }
}

/// Status do plano atual dentro do [PaywallPlanStudio] — evita exibir preço R\$ 0.
class _StudioActiveStatusBanner extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color accent;
  final bool isDark;

  const _StudioActiveStatusBanner({
    required this.ink,
    required this.mute,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assinatura ativa',
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cobrança e renovação na ${subscriptionChannelLabel()}. '
                  'Valores exatos aparecem nas configurações da loja.',
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreBillingHint extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;

  const _StoreBillingHint({
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PaywallInsetPanel(
      accent: TokensStrip.primary,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_outlined, size: 18, color: mute),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preços e upgrade disponíveis na ${subscriptionChannelLabel()} '
              'deste dispositivo. Abra a loja para concluir.',
              style: TokensStrip.bodyMuted(
                color: PaywallCatalog.readableSecondary(ink, mute, isDark: isDark),
              ).copyWith(fontSize: 13),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PaywallInsetPanel(
      accent: PaywallCatalog.green,
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  'ENTERPRISE' => PaywallCatalog.tierEnterprise,
  'ENT. PRO' => PaywallCatalog.brandDeep,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s1, bottom: TokensStrip.s3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackNote = constraints.maxWidth < 400 && note != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackNote) ...[
                Text(
                  title,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: TokensStrip.fontH2,
                    letterSpacing: TokensStrip.trackingH2,
                    height: 1.15,
                    color: ink,
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  note!,
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(
                    fontSize: TokensStrip.fontBodySm,
                    height: 1.4,
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: TokensStrip.fontH2,
                          letterSpacing: TokensStrip.trackingH2,
                          height: 1.15,
                          color: ink,
                        ),
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(width: TokensStrip.s3),
                      Flexible(
                        child: Text(
                          note!,
                          textAlign: TextAlign.end,
                          style: TokensStrip.bodyMuted(color: secondary).copyWith(
                            fontSize: TokensStrip.fontBodySm,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 10),
              Divider(height: 1, color: secondary.withValues(alpha: 0.35)),
            ],
          );
        },
      ),
    );
  }
}

/// Bloco recolhível — monta o filho só após a primeira expansão (performance).
class PaywallCollapsibleBlock extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool initiallyExpanded;
  final bool subscriberFlat;
  final bool expandRequested;

  const PaywallCollapsibleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.initiallyExpanded = false,
    this.subscriberFlat = false,
    this.expandRequested = false,
  });

  @override
  State<PaywallCollapsibleBlock> createState() => _PaywallCollapsibleBlockState();
}

class _PaywallCollapsibleBlockState extends State<PaywallCollapsibleBlock> {
  late bool _expanded;
  late bool _mountedChild;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded || widget.expandRequested;
    _mountedChild = _expanded;
  }

  @override
  void didUpdateWidget(PaywallCollapsibleBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandRequested && !_expanded) {
      setState(() {
        _expanded = true;
        _mountedChild = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.subscriberFlat;
    final reducedMotion = TokensStrip.prefersReducedMotion(context);
    final useBlur = _expanded && !flat && !reducedMotion;
    return PaywallGlassCard(
      margin: const EdgeInsets.only(bottom: TokensStrip.s4),
      accent: PaywallCatalog.brandDeep,
      glow: false,
      glowStrength: 0.2,
      blur: useBlur,
      elevationLevel: flat ? 7 : (_expanded ? 10 : 7),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (!flat)
            PaywallTierChrome.cardWash(
              accent: PaywallCatalog.brandDeep,
              isDark: widget.isDark,
              emphasis:
                  _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
            ),
          if (!flat)
            PaywallTierChrome.accentRail(
              PaywallCatalog.brandDeep,
              emphasis:
                  _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
            ),
          Theme(
            data: PaywallTierChrome.expansionTheme(context, TokensStrip.primary),
            child: Semantics(
              button: true,
              expanded: _expanded,
              label:
                  '${widget.title}. ${widget.subtitle}'
                  '${_expanded ? '' : '. Toque para expandir'}',
              hint: _expanded ? 'Recolher seção' : 'Expandir seção',
              child: ExpansionTile(
                initiallyExpanded: _expanded,
                onExpansionChanged: (open) {
                  setState(() {
                    _expanded = open;
                    if (open) _mountedChild = true;
                  });
                },
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  widget.title,
                  style: TokensStrip.h2(color: widget.ink).copyWith(fontSize: 17),
                ),
                subtitle: Text(
                  widget.subtitle,
                  style: TokensStrip.bodyMuted(color: widget.mute).copyWith(fontSize: 13),
                ),
                trailing: _PaywallExpandTrailing(expanded: _expanded, mute: widget.mute),
                children: [
                  AnimatedSize(
                    duration: TokensStrip.prefersReducedMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _mountedChild ? widget.child : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallExpandTrailing extends StatelessWidget {
  final bool expanded;
  final Color mute;

  const _PaywallExpandTrailing({required this.expanded, required this.mute});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expanded ? 'Recolher' : 'Ver detalhes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: mute,
          ),
        ),
        const SizedBox(width: 2),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Icon(Icons.keyboard_arrow_down_rounded, color: mute, size: 22),
        ),
      ],
    );
  }
}

class PaywallRoiBundle extends StatelessWidget {
  final Color line;
  final Color ink;
  final Color mute;
  final bool isDark;

  const PaywallRoiBundle({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaywallRoiStrip(line: line, ink: ink, mute: mute),
        const SizedBox(height: 12),
        PaywallRoiRowsList(ink: ink, mute: mute, line: line, isDark: isDark),
      ],
    );
  }
}

class _PaywallCompareDiffRow extends StatelessWidget {
  final String feature;
  final Color targetAccent;
  final Color ink;
  final Color mute;
  final bool isDark;
  final bool isLast;

  const _PaywallCompareDiffRow({
    required this.feature,
    required this.targetAccent,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: PaywallInsetPanel(
        accent: targetAccent,
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18, color: targetAccent),
            const SizedBox(width: 10),
            Expanded(
              child: PaywallFeatureLabel(
                raw: feature,
                ink: ink,
                accent: targetAccent,
                maxLines: 2,
                style: TokensStrip.body(color: ink).copyWith(
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PlanChip(label: 'SÓ PRO', color: targetAccent),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = PaywallCatalog.readableTierAccent(color, isDark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.38 : 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
          height: 1.1,
          color: fg,
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
  final bool allowLockedTap;

  const PaywallFeatureLine({
    super.key,
    required this.feature,
    required this.accent,
    required this.mute,
    required this.ink,
    this.onHelp,
    this.allowLockedTap = true,
  });

  String _tierBadgeLabel(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => 'PRO',
    SubscriptionPlan.ENTERPRISE => 'ENT',
    SubscriptionPlan.PREMIUM => 'PREMIUM',
    _ => 'FREE',
  };

  Future<void> _onLockedTap(BuildContext context) async {
    final parsed = PaywallCatalog.parseFeatureLabel(feature.row.label);
    await UpgradePromptSheet.show(
      context: context,
      featureName: parsed.label,
      capability: feature.capability,
      requiredPlan: feature.upgradePlan,
      source: 'paywall_feature_line',
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = feature.row;
    final off = !row.included;
    final upgradePlan = feature.upgradePlan;
    final tierName = upgradePlan != null
        ? PaywallCatalog.displayPlanName(upgradePlan)
        : 'Enterprise Pro';
    final status = row.included
        ? 'Incluído no plano'
        : 'Bloqueado. Disponível no plano $tierName.'
            '${allowLockedTap ? " Toque para ver upgrade." : ""}';
    final lockedInk = mute.withValues(alpha: 0.72);
    final canTapLocked = off && allowLockedTap && upgradePlan != null;

    final rowBody = Row(
      children: [
        Icon(
          row.included ? Icons.check_circle_rounded : Icons.lock_rounded,
          size: 18,
          color: row.included ? PaywallCatalog.green : lockedInk,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PaywallFeatureLabel(
            raw: row.label,
            ink: off ? lockedInk : ink,
            accent: accent,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w500,
              color: off ? lockedInk : ink,
            ),
          ),
        ),
        if (off && upgradePlan != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Semantics(
              label: 'Requer plano $tierName',
              child: _PlanChip(
                label: _tierBadgeLabel(upgradePlan),
                color: PaywallCatalog.accentForPlan(upgradePlan),
              ),
            ),
          ),
        if (row.highlight && row.included)
          Semantics(
            label: 'Destaque do plano',
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: PaywallCatalog.brandDeep,
            ),
          ),
        if (row.comingSoon)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _PlanChip(label: 'EM BREVE', color: PaywallCatalog.warning),
          ),
        if (feature.education != null)
          Semantics(
            button: true,
            label: 'Saiba mais sobre ${row.label}',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(Icons.help_outline_rounded, size: 18, color: mute),
              onPressed: () {
                onHelp?.call();
                final parsed = PaywallCatalog.parseFeatureLabel(row.label);
                showPaywallFeatureEducation(
                  context,
                  feature.education!,
                  onViewPlan: feature.upgradePlan != null
                      ? () {
                          UpgradePromptSheet.show(
                            context: context,
                            featureName: parsed.label,
                            capability: feature.capability,
                            requiredPlan: feature.upgradePlan!,
                            source: 'paywall_education_sheet',
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        if (canTapLocked)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: mute.withValues(alpha: 0.55),
          ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: rowBody,
    );

    if (!canTapLocked) {
      return Semantics(label: status, child: padded);
    }

    return Semantics(
      button: true,
      label: status,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onLockedTap(context);
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: padded,
        ),
      ),
    );
  }
}

SubscriptionPlan? _educationTargetPlan(List<String> planNames) {
  SubscriptionPlan? best;
  for (final name in planNames) {
    final tier = subscriptionPlanFromApi(name);
    if (best == null || tier.level > best.level) best = tier;
  }
  return best;
}

void showPaywallFeatureEducation(
  BuildContext context,
  PaywallEducationContent content, {
  VoidCallback? onViewPlan,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetInk = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
  final sheetMute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  final sheetLine = isDark ? EagleTokens.darkLine : EagleTokens.line;
  final targetPlan = _educationTargetPlan(content.plans);
  final targetLabel = targetPlan == null
      ? null
      : PaywallCatalog.displayPlanName(targetPlan);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: TokensStrip.blurFilter(TokensStrip.blurMedium),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TokensStrip.glassFill(
                    dark: isDark,
                    opacity: isDark ? 0.92 : 0.96,
                  ),
                  border: Border(
                    top: BorderSide(color: sheetLine.withValues(alpha: 0.5)),
                  ),
                ),
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              Text(
                'O que é',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(content.whatIs, style: TokensStrip.body(color: sheetMute)),
              const SizedBox(height: 14),
              Text(
                'Por que importa pra você',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(content.whyMatters, style: TokensStrip.body(color: sheetMute)),
              if (content.roiStatement != null) ...[
                const SizedBox(height: 14),
                PaywallInsetPanel(
                  accent: PaywallCatalog.green,
                  isDark: isDark,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        size: 18,
                        color: PaywallCatalog.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          content.roiStatement!,
                          style: const TextStyle(
                            color: PaywallCatalog.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Disponível em',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: content.plans
                    .map((p) => _PlanChip(label: p, color: PaywallCatalog.accentForPlan(
                      subscriptionPlanFromApi(p),
                    )))
                    .toList(),
              ),
              if (targetPlan != null && onViewPlan != null) ...[
                const SizedBox(height: 20),
                FxLiquidPrimaryButton(
                  label: 'Ver $targetLabel',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onViewPlan();
                  },
                ),
              ],
              const SizedBox(height: 10),
              FxLiquidSecondaryButton(
                label: 'Fechar',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
        },
      );
    },
  );
}

