part of 'assinatura_screen.dart';

extension AssinaturaScreenBuildBody on _AssinaturaScreenState {
  Widget buildPaywallPlansScroll({
    required List<Plano> planosList,
    required SubscriptionPlan currentPlan,
    required Color ink,
    required Color mute,
    required Color line,
    required Color primary,
    required bool isDark,
    required AsyncValue<PlanoFeatures?> featuresAsync,
    required PaywallVitrineSnapshot? vitrine,
    required bool showEnterpriseProStickySecondary,
    required List<PaywallComparisonRow> vitrineComparison,
    required int? trialDaysFromVitrine,
    required SubscriptionPlan? paywallNextTier,
    required bool paywallHasUpgradeAbove,
    required String? enterpriseProRoiTag,
  }) {
    final sortedPlans = [...planosList]..sort(
      (a, b) => subscriptionPlanFromApi(
        a.nome,
      ).level.compareTo(subscriptionPlanFromApi(b.nome).level),
    );
    final paid =
        sortedPlans
            .where(
              (p) => subscriptionPlanFromApi(p.nome) != SubscriptionPlan.FREE,
            )
            .toList();

    if (paid.isEmpty) {
      return FxEmptyState(
        icon: 'dollar-sign',
        title: 'Nenhum plano pago disponível',
        subtitle: 'Tente atualizar em instantes.',
        action: FxEmptyAction(
          label: 'Atualizar',
          onTap: () {
            ref.invalidate(paywallHomeProvider);
          },
        ),
      );
    }

    var selPlan = subscriptionPlanFromApi(
      _selectedPlanName ?? currentPlan.apiName,
    );
    if (selPlan == SubscriptionPlan.FREE) {
      selPlan = subscriptionPlanFromApi(paid.last.nome);
    }

    final selBackend = sortedPlans.firstWhere(
      (plan) => subscriptionPlanFromApi(plan.nome) == selPlan,
      orElse: () => paid.last,
    );
    final currentBackend = sortedPlans.firstWhere(
      (plan) => subscriptionPlanFromApi(plan.nome) == currentPlan,
      orElse: () => selBackend,
    );
    final isCurrentPlanSelected = selPlan == currentPlan;
    final isAcquisition = currentPlan == SubscriptionPlan.FREE;
    final isMaxTier = currentPlan == SubscriptionPlan.ENTERPRISE_PRO;
    final hasUpgradeAbove = paid.any(
      (p) => subscriptionPlanFromApi(p.nome).level > currentPlan.level,
    );
    final heroPlanLabel = PaywallCatalog.displayNameFor(
      currentBackend,
      currentPlan,
    );
    SubscriptionPlan? nextTierPlan;
    for (final p in paid) {
      final tier = subscriptionPlanFromApi(p.nome);
      if (tier.level > currentPlan.level &&
          (nextTierPlan == null || tier.level > nextTierPlan.level)) {
        nextTierPlan = tier;
      }
    }
    if (_shouldLoadEnterprisePreview(currentPlan, selPlan) &&
        !_enterprisePreviewRequested) {
      _enterprisePreviewRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadEnterprisePreview();
      });
    }

    final meFeatures = featuresAsync.valueOrNull?.alignedToBilling(currentPlan);
    if (meFeatures != null) {
      _maybeReconcilePlanOnLoad(
        billingPlan: currentPlan,
        meFeatures: featuresAsync.valueOrNull,
      );
    }

    final usage =
        meFeatures == null
            ? null
            : PlanEntitlements.snapshotFrom(
              plano: meFeatures.plano,
              billingPlan: currentPlan,
              serverPlano: featuresAsync.valueOrNull?.plano,
              alunosAtivos: meFeatures.alunosAtivos,
              limiteAlunos: meFeatures.limiteAlunos,
              iaUsadaMes: meFeatures.iaUsadaMes,
              limiteIaMensal: meFeatures.limiteIaMensal,
              iaRestantes: meFeatures.iaRestantes,
            );

    final isUpgradeTargetSelected = selPlan.level > currentPlan.level;
    final usePlanStudio =
        !isAcquisition && currentPlan != SubscriptionPlan.FREE;

    return ListView(
      controller: _paywallScrollController,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s5,
        4,
        TokensStrip.s5,
        140,
      ),
      children: [
        if (!usePlanStudio)
          PaywallHero(
            ink: ink,
            mute: mute,
            primary: primary,
            isDark: isDark,
            currentPlan: currentPlan,
            planDisplayLabel: heroPlanLabel,
            isMaxTier: isMaxTier,
            hasUpgradePath: hasUpgradeAbove,
            viewingCurrentPlan: isCurrentPlanSelected,
            upgradeOffersExpanded:
                _upgradeOffersExpanded || isUpgradeTargetSelected,
            upgradeTargetSelected: isUpgradeTargetSelected,
          ),
        if (isAcquisition)
          PaywallQuickNav(
            primary: primary,
            ink: isDark ? EagleTokens.darkInk : EagleTokens.inkDeep,
            onSectionTap: _scrollToPaywallSection,
          )
        else if (!usePlanStudio)
          PaywallSubscriberQuickNav(
            primary: primary,
            ink: isDark ? EagleTokens.darkInk : EagleTokens.inkDeep,
            onSectionTap: _scrollToPaywallSection,
          ),
        if (usage != null &&
            (!usePlanStudio ||
                (widget.blockedFeature != null &&
                    widget.blockedFeature!.isNotEmpty) ||
                widget.blockedCapability != null))
          PaywallContextBanner(
            usage: usage,
            blockedFeatureLabel: widget.blockedFeature,
            blockedCapability: widget.blockedCapability,
            ink: ink,
            mute: mute,
            onCta: () {
              final target = PlanEntitlements.resolveUpgradeTarget(
                usage: usage,
                blockedFeatureLabel: widget.blockedFeature,
                blockedCapability: widget.blockedCapability,
              );
              _selectPlan(target);
            },
          ),
        if (!usePlanStudio)
          PaywallSectionAnchor(
            anchorKey: _paywallPlanosKey,
            child: PaywallSectionHeader(
              title: 'Planos',
              note:
                  isAcquisition
                      ? 'Toque no card · Mensal ou Anual'
                      : isMaxTier
                      ? 'Plano máximo · gerencie na loja'
                      : hasUpgradeAbove
                      ? (isCurrentPlanSelected
                          ? 'Seu plano · upgrade opcional recolhido'
                          : 'Upgrade no card · downgrade na loja')
                      : 'Gerencie na loja do dispositivo',
              ink: ink,
              mute: mute,
            ),
          ),
        ...() {
          Plano? freePlano;
          for (final p in sortedPlans) {
            if (subscriptionPlanFromApi(p.nome) == SubscriptionPlan.FREE) {
              freePlano = p;
              break;
            }
          }
          final visiblePlans =
              currentPlan == SubscriptionPlan.FREE
                  ? sortedPlans
                  : sortedPlans
                      .where(
                        (p) =>
                            subscriptionPlanFromApi(p.nome) !=
                            SubscriptionPlan.FREE,
                      )
                      .toList();

          final hasUpgradeAbove = visiblePlans.any(
            (p) => subscriptionPlanFromApi(p.nome).level > currentPlan.level,
          );

          Widget planCard(
            Plano plano, {
            bool lockedDowngrade = false,
            bool referenceOnly = false,
          }) {
            final plan = subscriptionPlanFromApi(plano.nome);
            final isReferenceCard =
                referenceOnly ||
                (usePlanStudio &&
                    (lockedDowngrade || plan == SubscriptionPlan.FREE));
            final monthlyProduct =
                _productDetails[SubscriptionProducts.productIdFor(
                  plan,
                  SubscriptionBillingPeriod.monthly,
                )];
            final annualProduct =
                _productDetails[SubscriptionProducts.productIdFor(
                  plan,
                  SubscriptionBillingPeriod.yearly,
                )];
            final monthlyPrice =
                monthlyProduct != null
                    ? monthlyProduct.price.replaceAll(RegExp(r'/.*'), '')
                    : paywallMonthlyFromPlano(plano);
            final annualPrice =
                annualProduct != null
                    ? annualProduct.price.replaceAll(RegExp(r'/.*'), '')
                    : paywallAnnualMonthlyEquiv(plano);
            final storeOk =
                kIsWeb || !subscriptionUsesNativeStore || _storeAvailable;
            final isUpgradeTier =
                !lockedDowngrade &&
                plan.level > currentPlan.level &&
                !isAcquisition;
            final upsellHighlights =
                isUpgradeTier
                    ? _paywallUpgradeGains(
                      currentBackend,
                      currentPlan,
                      plano,
                      plan,
                    ).map((r) => r.label).take(3).toList()
                    : const <String>[];
            final nestedInAccordion = plan != currentPlan || lockedDowngrade;
            final cardKey =
                isUpgradeTier && plan == selPlan
                    ? _paywallUpgradeTargetKey
                    : null;
            return PaywallRichPlanCard(
              key: cardKey,
              plano: plano,
              plan: plan,
              embeddedInStudio: usePlanStudio && !lockedDowngrade,
              showFeatureLegend: false,
              isSelected: plan == selPlan && !lockedDowngrade,
              isCurrent: plan == currentPlan,
              isLockedDowngrade: lockedDowngrade,
              referenceOnly: isReferenceCard,
              nestedInAccordion: usePlanStudio ? false : nestedInAccordion,
              dimUnselected:
                  usePlanStudio
                      ? false
                      : hasUpgradeAbove &&
                          plan != currentPlan &&
                          plan != selPlan,
              collapseFeatureDetails:
                  (plan == currentPlan &&
                      currentPlan != SubscriptionPlan.FREE) ||
                  (usePlanStudio &&
                      plan == selPlan &&
                      plan.level > currentPlan.level),
              compactUpsell:
                  !usePlanStudio &&
                  isUpgradeTier &&
                  upsellHighlights.isNotEmpty,
              upsellHighlights: upsellHighlights,
              billingDisabled:
                  !storeOk &&
                  plan.level > currentPlan.level &&
                  !kIsWeb &&
                  subscriptionUsesNativeStore,
              monthlyPrice: monthlyPrice,
              annualPrice: annualPrice,
              ink: ink,
              mute: mute,
              line: line,
              isDark: isDark,
              onFeatureHelp: () {},
              billingPeriod:
                  plan == selPlan &&
                          !lockedDowngrade &&
                          !kIsWeb &&
                          subscriptionUsesNativeStore &&
                          storeOk
                      ? _billingPeriod
                      : null,
              onBillingPeriodTap:
                  lockedDowngrade ||
                          plan == SubscriptionPlan.FREE ||
                          kIsWeb ||
                          !subscriptionUsesNativeStore ||
                          !storeOk
                      ? null
                      : (period) {
                        HapticFeedback.selectionClick();
                        AnalyticsService.instance.track(
                          ProductEvents.billingToggleChanged,
                          props: {'to': period.name, 'source': 'plan_card'},
                        );
                        setState(() => _billingPeriod = period);
                        _selectPlan(plan);
                      },
              onTap:
                  isReferenceCard
                      ? _handleDowngradeTierTap
                      : usePlanStudio
                      ? null
                      : lockedDowngrade
                      ? _handleDowngradeTierTap
                      : () {
                        HapticFeedback.selectionClick();
                        _selectPlan(plan);
                      },
            );
          }

          final upgradePlans =
              visiblePlans
                  .where(
                    (p) =>
                        subscriptionPlanFromApi(p.nome).level >=
                        currentPlan.level,
                  )
                  .toList();
          final currentTierPlans =
              upgradePlans
                  .where((p) => subscriptionPlanFromApi(p.nome) == currentPlan)
                  .toList();
          final upperTierPlans =
              upgradePlans
                  .where(
                    (p) =>
                        subscriptionPlanFromApi(p.nome).level >
                        currentPlan.level,
                  )
                  .toList();
          final showUpgradeAccordion =
              !isAcquisition &&
              upperTierPlans.isNotEmpty &&
              currentPlan != SubscriptionPlan.FREE;
          final upgradeExpanded =
              _upgradeOffersExpanded || selPlan.level > currentPlan.level;
          final lowerPlans =
              visiblePlans
                  .where(
                    (p) =>
                        subscriptionPlanFromApi(p.nome).level <
                        currentPlan.level,
                  )
                  .toList();

          if (usePlanStudio) {
            Widget? studioBelowPlan;
            if (_enterprisePreview != null &&
                _enterprisePreviewIsInformative(
                  _enterprisePreview!,
                  currentPlan,
                  selPlan,
                )) {
              studioBelowPlan = _EnterprisePreviewCard(
                preview: _enterprisePreview!,
                primary: primary,
                ink: ink,
                mute: mute,
                isDark: isDark,
              );
            } else if (isUpgradeTargetSelected &&
                currentPlan == SubscriptionPlan.ENTERPRISE &&
                selPlan == SubscriptionPlan.ENTERPRISE_PRO) {
              studioBelowPlan = _EnterpriseProUpgradePriceHint(
                currentPlan: currentPlan,
                targetPlan: selPlan,
                billingPeriod: _billingPeriod,
                productDetails: _productDetails,
                currentBackend: currentBackend,
                targetBackend: selBackend,
                primary: primary,
                ink: ink,
                mute: mute,
                isDark: isDark,
              );
            }

            Widget? studioCompare;
            if (isCurrentPlanSelected &&
                currentPlan == SubscriptionPlan.ENTERPRISE &&
                nextTierPlan == SubscriptionPlan.ENTERPRISE_PRO) {
              studioCompare = PaywallSectionAnchor(
                anchorKey: _paywallCompareKey,
                child: PaywallSubscriberQuickCompare(
                  currentPlan: currentPlan,
                  targetPlan: nextTierPlan,
                  comparisonRows: vitrineComparison,
                  catalogFromApi: vitrine?.fromApi ?? false,
                  initiallyExpanded: false,
                  expandRequested: _compareRevealed,
                  onReveal: () {
                    HapticFeedback.selectionClick();
                    setState(() => _compareRevealed = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _scrollToPaywallSection(PaywallScrollTarget.comparar);
                    });
                  },
                  ink: ink,
                  mute: mute,
                  line: line,
                  primary: primary,
                  isDark: isDark,
                ),
              );
            }

            return [
              PaywallSectionAnchor(
                anchorKey: _paywallPlanosKey,
                child: PaywallPlanStudio(
                  currentPlan: currentPlan,
                  selectedPlan: selPlan,
                  studioPlanos: upgradePlans,
                  isMaxTier: isMaxTier,
                  onPlanSelected: (plan) {
                    HapticFeedback.selectionClick();
                    setState(
                      () =>
                          _upgradeOffersExpanded =
                              plan.level > currentPlan.level,
                    );
                    _selectPlan(plan);
                  },
                  onExplorePro: _focusEnterpriseProUpgrade,
                  onScrollToUsage:
                      () => _scrollToPaywallSection(PaywallScrollTarget.planos),
                  showCompareAnchor:
                      isCurrentPlanSelected &&
                      currentPlan == SubscriptionPlan.ENTERPRISE &&
                      nextTierPlan == SubscriptionPlan.ENTERPRISE_PRO,
                  planContent: planCard(selBackend),
                  compareSection: studioCompare,
                  belowPlanSection: studioBelowPlan,
                  roiTag: enterpriseProRoiTag,
                  usageSnapshot: usage,
                  showProExploreStrip: !showEnterpriseProStickySecondary,
                  planMismatch:
                      featuresAsync.valueOrNull != null &&
                      featuresAsync.value!.plano.level < currentPlan.level,
                  syncWarning: () {
                    final warning = featuresAsync.valueOrNull?.syncWarning;
                    if (warning == null || warning.isEmpty) {
                      return null;
                    }
                    final mismatch =
                        featuresAsync.valueOrNull != null &&
                        featuresAsync.value!.plano.level < currentPlan.level;
                    if (selPlan.level > currentPlan.level && !mismatch) {
                      return null;
                    }
                    return warning;
                  }(),
                  onRefreshPlan: () {
                    unawaited(_reconcilePlanFromServer());
                  },
                  ink: ink,
                  mute: mute,
                  isDark: isDark,
                ),
              ),
              if ((lowerPlans.isNotEmpty || freePlano != null) &&
                  selPlan.level <= currentPlan.level)
                PaywallGlassAccordion(
                  ink: ink,
                  mute: mute,
                  isDark: isDark,
                  accent: PaywallCatalog.chromeNeutral(ink, isDark: isDark),
                  title: 'Outros planos',
                  subtitle:
                      'Downgrade e plano gratuito · só pela ${subscriptionChannelLabel()}',
                  children: [
                    PaywallOtherPlansIntro(
                      ink: ink,
                      mute: mute,
                      isDark: isDark,
                    ),
                    for (var i = 0; i < lowerPlans.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            color: line.withValues(alpha: 0.45),
                          ),
                        ),
                      planCard(lowerPlans[i], lockedDowngrade: true),
                    ],
                    if (lowerPlans.isNotEmpty && freePlano != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          height: 1,
                          color: line.withValues(alpha: 0.45),
                        ),
                      ),
                    if (freePlano != null) planCard(freePlano),
                  ],
                ),
            ];
          }

          return [
            ...currentTierPlans.map((p) => planCard(p)),
            if (showUpgradeAccordion)
              PaywallSectionAnchor(
                anchorKey: _paywallUpgradeKey,
                child: PaywallGlassAccordion(
                  tileKey: const ValueKey('paywall_upgrade_accordion'),
                  initiallyExpanded: upgradeExpanded,
                  onExpansionChanged: (open) {
                    setState(() => _upgradeOffersExpanded = open);
                    final tier = nextTierPlan;
                    if (open && tier != null) {
                      _selectPlan(tier);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _scrollToUpgradeTargetCard();
                      });
                    }
                  },
                  accent:
                      nextTierPlan == null
                          ? primary
                          : PaywallCatalog.accentForPlan(nextTierPlan),
                  ink: ink,
                  mute: mute,
                  isDark: isDark,
                  title:
                      nextTierPlan == null
                          ? 'Upgrade disponível'
                          : 'Upgrade disponível — ${PaywallCatalog.displayPlanName(nextTierPlan)}',
                  subtitle:
                      'Preços e benefícios na ${subscriptionChannelLabel()}',
                  children: [for (final p in upperTierPlans) planCard(p)],
                ),
              )
            else
              ...upperTierPlans.map((p) => planCard(p)),
            if (lowerPlans.isNotEmpty && currentPlan != SubscriptionPlan.FREE)
              PaywallGlassAccordion(
                ink: ink,
                mute: mute,
                isDark: isDark,
                accent: TokensStrip.primary,
                title: 'Outros planos e downgrade',
                subtitle:
                    'Mudança de tier só pela ${subscriptionChannelLabel()}',
                children: [
                  for (final p in lowerPlans)
                    planCard(p, lockedDowngrade: true),
                ],
              ),
            if (currentPlan != SubscriptionPlan.FREE && freePlano != null)
              PaywallGlassAccordion(
                ink: ink,
                mute: mute,
                isDark: isDark,
                title: 'Ver plano gratuito',
                subtitle: 'Plano gratuito para referência',
                children: [planCard(freePlano)],
              ),
          ];
        }(),
        if (currentPlan == SubscriptionPlan.PREMIUM &&
            selPlan == SubscriptionPlan.ENTERPRISE &&
            !isCurrentPlanSelected) ...[
          const SizedBox(height: 16),
          _PaywallUpgradeNudge(primary: primary, ink: ink, isDark: isDark),
        ],
        if (!usePlanStudio && !isUpgradeTargetSelected) ...[
          const SizedBox(height: 8),
          _PaywallFeaturePanel(
            plano: isCurrentPlanSelected ? currentBackend : selBackend,
            currentPlano: currentBackend,
            plan: isCurrentPlanSelected ? currentPlan : selPlan,
            currentPlan: currentPlan,
            usage: featuresAsync.valueOrNull,
            ink: ink,
            mute: mute,
            line: line,
            primary: primary,
            isDark: isDark,
          ),
        ],
        if (isAcquisition)
          PaywallWebDetailsLink(
            ink: ink,
            mute: mute,
            primary: primary,
            line: line,
            isDark: isDark,
          )
        else if (!usePlanStudio && hasUpgradeAbove && nextTierPlan != null)
          PaywallSectionAnchor(
            anchorKey: _paywallCompareKey,
            child: PaywallSubscriberQuickCompare(
              currentPlan: currentPlan,
              targetPlan: nextTierPlan,
              comparisonRows: vitrineComparison,
              catalogFromApi: vitrine?.fromApi ?? false,
              initiallyExpanded:
                  selPlan == nextTierPlan && selPlan.level > currentPlan.level,
              ink: ink,
              mute: mute,
              line: line,
              primary: primary,
              isDark: isDark,
            ),
          ),
        const SizedBox(height: 12),
        if (!usePlanStudio &&
            _shouldShowEnterpriseTrialCard(
              selPlan,
              currentPlan,
              _trialStatus,
            )) ...[
          const SizedBox(height: 16),
          _PaywallInlineNote(
            icon: Icons.card_giftcard_outlined,
            text:
                _loadingTrial
                    ? 'Carregando oferta de teste…'
                    : subscriptionUsesNativeStore
                    ? 'Teste introdutório configurado na ${subscriptionChannelLabel()}.'
                    : '${_trialStatus?.trialDaysOffer ?? 14} dias grátis neste plano Enterprise.',
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ],
        if (!usePlanStudio &&
            _enterprisePreview != null &&
            _enterprisePreviewIsInformative(
              _enterprisePreview!,
              currentPlan,
              selPlan,
            )) ...[
          const SizedBox(height: 12),
          _EnterprisePreviewCard(
            preview: _enterprisePreview!,
            primary: primary,
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ] else if (!usePlanStudio &&
            isUpgradeTargetSelected &&
            currentPlan == SubscriptionPlan.ENTERPRISE &&
            selPlan == SubscriptionPlan.ENTERPRISE_PRO) ...[
          const SizedBox(height: 12),
          _EnterpriseProUpgradePriceHint(
            currentPlan: currentPlan,
            targetPlan: selPlan,
            billingPeriod: _billingPeriod,
            productDetails: _productDetails,
            currentBackend: currentBackend,
            targetBackend: selBackend,
            primary: primary,
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ],
        if (!_storeAvailable &&
            !kIsWeb &&
            subscriptionUsesNativeStore &&
            !isAcquisition &&
            !hasUpgradeAbove) ...[
          const SizedBox(height: 12),
          _PaywallInlineNote(
            icon: Icons.store_outlined,
            text:
                'Loja indisponível nesta sessão — use o botão abaixo para abrir ${subscriptionChannelLabel()} e gerenciar sua assinatura.',
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ],
        if (kIsWeb) ...[
          const SizedBox(height: 12),
          _PaywallInlineNote(
            icon: Icons.smartphone_outlined,
            text: 'No celular, assine pela App Store ou Google Play.',
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ],
        if (!(usePlanStudio && isUpgradeTargetSelected)) ...[
          const SizedBox(height: 16),
          PaywallSectionAnchor(
            anchorKey: _paywallLegalKey,
            child:
                !isAcquisition && isCurrentPlanSelected
                    ? PaywallSubscriberLegalStrip(
                      mute: mute,
                      primary: primary,
                      restoring: _restoringPurchases,
                      onRestore:
                          subscriptionUsesNativeStore
                              ? _restorePurchases
                              : null,
                    )
                    : PaywallUpgradeLegalCompact(
                      ink: ink,
                      mute: mute,
                      primary: primary,
                      showStoreBillingNote: subscriptionUsesNativeStore,
                      restoring: _restoringPurchases,
                      onRestore:
                          subscriptionUsesNativeStore
                              ? _restorePurchases
                              : null,
                    ),
          ),
        ],
      ],
    );
  }
}
