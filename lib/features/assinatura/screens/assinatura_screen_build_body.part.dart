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
    required SubscriptionPlan? paywallNextTier,
    required bool paywallHasUpgradeAbove,
  }) {
    final sortedPlans = [...planosList]..sort(
      (a, b) => subscriptionPlanFromApi(
        a.nome,
      ).level.compareTo(subscriptionPlanFromApi(b.nome).level),
    );

    if (sortedPlans.isEmpty) {
      return FxEmptyState(
        icon: 'dollar-sign',
        title: 'Nenhum plano disponível',
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
    final tabPlans =
        sortedPlans
            .map((p) => subscriptionPlanFromApi(p.nome))
            .toList(growable: false);
    if (!tabPlans.contains(selPlan)) {
      selPlan = tabPlans.first;
    }

    final isAcquisition = currentPlan == SubscriptionPlan.FREE;
    final hasUpgradeAbove =
        paywallHasUpgradeAbove ||
        (paywallNextTier != null && paywallNextTier.level > currentPlan.level);

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

    final storeOk = kIsWeb || !subscriptionUsesNativeStore || _storeAvailable;
    final showBilling =
        selPlan != SubscriptionPlan.FREE &&
        !kIsWeb &&
        subscriptionUsesNativeStore &&
        storeOk;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paywallHomeProvider);
        ref.invalidate(planoFeaturesProvider);
        await ref.read(paywallHomeProvider.future);
      },
      child: CustomScrollView(
        controller: _paywallScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s5,
              TokensStrip.s1,
              TokensStrip.s5,
              TokensStrip.s3,
            ),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usage != null &&
                      ((widget.blockedFeature != null &&
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
                  Expanded(
                    child: PaywallCompareStage(
                      fillViewport: true,
                      plans: tabPlans,
                      currentPlan: currentPlan,
                      selectedPlan: selPlan,
                      comparisonRows:
                          vitrine?.rowsFor(selPlan) ??
                          (selPlan == SubscriptionPlan.ENTERPRISE
                              ? PaywallCatalog.comparisonFreeVsEnterprise
                              : PaywallCatalog.comparisonFreeVsPro),
                      billingPeriod: _billingPeriod,
                      onSelectPlan: _selectPlan,
                      onBillingPeriod:
                          showBilling
                              ? (period) {
                                AnalyticsService.instance.track(
                                  ProductEvents.billingToggleChanged,
                                  props: {
                                    'to': period.name,
                                    'source': 'compare_tabs',
                                  },
                                );
                                setState(() => _billingPeriod = period);
                                _selectPlan(selPlan);
                              }
                              : null,
                      ink: ink,
                      mute: mute,
                      isDark: isDark,
                      line: line,
                    ),
                  ),
                  if (!_storeAvailable &&
                      !kIsWeb &&
                      subscriptionUsesNativeStore &&
                      !isAcquisition &&
                      !hasUpgradeAbove) ...[
                    const SizedBox(height: TokensStrip.s3),
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
                    const SizedBox(height: TokensStrip.s3),
                    _PaywallInlineNote(
                      icon: Icons.smartphone_outlined,
                      text: 'No celular, assine pela App Store ou Google Play.',
                      ink: ink,
                      mute: mute,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
