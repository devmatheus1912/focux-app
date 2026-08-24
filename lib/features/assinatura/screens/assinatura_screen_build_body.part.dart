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

    final selBackend = sortedPlans.firstWhere(
      (plan) => subscriptionPlanFromApi(plan.nome) == selPlan,
      orElse: () => sortedPlans.first,
    );
    final currentBackend = sortedPlans.firstWhere(
      (plan) => subscriptionPlanFromApi(plan.nome) == currentPlan,
      orElse: () => selBackend,
    );
    final isCurrentPlanSelected = selPlan == currentPlan;
    final isAcquisition = currentPlan == SubscriptionPlan.FREE;
    final isUpgradeTargetSelected = selPlan.level > currentPlan.level;
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final stickyReserve =
        TokensStrip.s8 * 3 + TokensStrip.s6 + bottomInset;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paywallHomeProvider);
        ref.invalidate(planoFeaturesProvider);
        await ref.read(paywallHomeProvider.future);
      },
      child: ListView(
        controller: _paywallScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          TokensStrip.s5,
          TokensStrip.s1,
          TokensStrip.s5,
          stickyReserve,
        ),
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
          PaywallSectionAnchor(
            anchorKey: _paywallPlanosKey,
            child: PaywallCompareStage(
              plans: tabPlans,
              currentPlan: currentPlan,
              selectedPlan: selPlan,
              comparisonRows: vitrineComparison,
              billingPeriod: _billingPeriod,
              onSelectPlan: _selectPlan,
              onBillingPeriod:
                  showBilling
                      ? (period) {
                        AnalyticsService.instance.track(
                          ProductEvents.billingToggleChanged,
                          props: {'to': period.name, 'source': 'compare_tabs'},
                        );
                        setState(() => _billingPeriod = period);
                        _selectPlan(selPlan);
                      }
                      : null,
              ink: ink,
              mute: mute,
              primary: primary,
              isDark: isDark,
              line: line,
              roiTag:
                  showEnterpriseProStickySecondary
                      ? null
                      : enterpriseProRoiTag,
            ),
          ),
          if (_shouldShowEnterpriseTrialCard(
            selPlan,
            currentPlan,
            _trialStatus,
          )) ...[
            const SizedBox(height: TokensStrip.s4),
            _PaywallInlineNote(
              icon: Icons.card_giftcard_outlined,
              text:
                  _loadingTrial
                      ? 'Carregando oferta de teste…'
                      : subscriptionUsesNativeStore
                      ? 'Teste introdutório configurado na ${subscriptionChannelLabel()}.'
                      : '${trialDaysFromVitrine ?? _trialStatus?.trialDaysOffer ?? 14} dias grátis neste plano Enterprise.',
              ink: ink,
              mute: mute,
              isDark: isDark,
            ),
          ],
          if (_enterprisePreview != null &&
              _enterprisePreviewIsInformative(
                _enterprisePreview!,
                currentPlan,
                selPlan,
              )) ...[
            const SizedBox(height: TokensStrip.s3),
            _EnterprisePreviewCard(
              preview: _enterprisePreview!,
              primary: primary,
              ink: ink,
              mute: mute,
              isDark: isDark,
            ),
          ] else if (isUpgradeTargetSelected &&
              currentPlan == SubscriptionPlan.ENTERPRISE &&
              selPlan == SubscriptionPlan.ENTERPRISE_PRO) ...[
            const SizedBox(height: TokensStrip.s3),
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
          if (!isAcquisition) ...[
            const SizedBox(height: TokensStrip.s4),
            PaywallSectionAnchor(
              anchorKey: _paywallLegalKey,
              child:
                  isCurrentPlanSelected
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
      ),
    );
  }
}
