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

