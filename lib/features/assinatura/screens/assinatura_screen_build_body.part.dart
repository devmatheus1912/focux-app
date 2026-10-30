part of 'assinatura_screen.dart';

extension AssinaturaScreenBuildBody on _AssinaturaScreenState {
  Widget buildPaywallPlansScroll({
    required bool gestao,
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
    bool managementMode = false,
  }) {
    final sortedPlans = [...planosList]..sort(
      (a, b) => subscriptionPlanFromApi(
        a.nome,
      ).level.compareTo(subscriptionPlanFromApi(b.nome).level),
    );

    if (sortedPlans.isEmpty) {
      return FxEmptyState(
        icon: 'dollar-sign',
        title: 'Planos em sincronização',
        subtitle:
            'Tente de novo em instantes.',
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

    final meFeatures = featuresAsync.value?.alignedToBilling(currentPlan);
    if (meFeatures != null) {
      _maybeReconcilePlanOnLoad(
        billingPlan: currentPlan,
        meFeatures: featuresAsync.value,
      );
    }

    final usage =
        meFeatures == null
            ? null
            : PlanEntitlements.snapshotFrom(
              plano: meFeatures.plano,
              billingPlan: currentPlan,
              serverPlano: featuresAsync.value?.plano,
              alunosAtivos: meFeatures.alunosAtivos,
              limiteAlunos: meFeatures.limiteAlunos,
              iaUsadaMes: meFeatures.iaUsadaMes,
              limiteIaMensal: meFeatures.limiteIaMensal,
              iaRestantes: meFeatures.iaRestantes,
            );

    if (gestao) {
      final s = S.of(context);
      final proximo = paywallNextTier;
      final loja = subscriptionUsesNativeStore;
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paywallHomeProvider);
          await ref.read(paywallHomeProvider.future);
        },
        child: AssinaturaGestaoView(
          planoNome: PaywallCatalog.displayPlanName(currentPlan),
          validoAte: meFeatures?.validoAte,
          usos: [
            if (meFeatures != null) ...[
              (
                rotulo: s.assinaturaUsoAlunos,
                usado: meFeatures.alunosAtivos,
                limite: meFeatures.limiteAlunos,
              ),
              if ((meFeatures.limiteIaMensal ?? 0) > 0)
                (
                  rotulo: s.assinaturaUsoIa,
                  usado: meFeatures.iaUsadaMes,
                  limite: meFeatures.limiteIaMensal,
                ),
            ],
          ],
          inclusos: paywallInclusos(
            vitrine?.rowsFor(currentPlan) ??
                (currentPlan == SubscriptionPlan.ENTERPRISE
                    ? PaywallCatalog.comparisonFreeVsEnterprise
                    : PaywallCatalog.comparisonFreeVsPro),
          ),
          gerenciarLabel: 'Gerenciar assinatura na loja',
          onGerenciar: loja && !_loadingCheckout ? _openSubscriptionManagement : null,
          onRestaurar: loja ? _restorePurchases : null,
          onTermos:
              () => _showAssinaturaTermosSheet(
                context,
                mute: mute,
                primary: primary,
                showStoreBillingNote: loja,
                restoring: _restoringPurchases,
                onRestore: loja ? _restorePurchases : null,
              ),
          superiorNome:
              proximo == null ? null : PaywallCatalog.displayPlanName(proximo),
          onSuperior: proximo == null ? null : () => _selectPlan(proximo),
          onCancelar: () => context.push('/cancel-save'),
        ),
      );
    }

    final storeOk = kIsWeb || !subscriptionUsesNativeStore || _storeAvailable;
    final managingCurrent = managementMode && selPlan == currentPlan;
    final showBilling =
        selPlan != SubscriptionPlan.FREE &&
        !kIsWeb &&
        subscriptionUsesNativeStore &&
        storeOk &&
        !managingCurrent;

    final linhas =
        vitrine?.rowsFor(selPlan) ??
        (selPlan == SubscriptionPlan.ENTERPRISE
            ? PaywallCatalog.comparisonFreeVsEnterprise
            : PaywallCatalog.comparisonFreeVsPro);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paywallHomeProvider);
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
                  // Planos in-app: sem lockup de marca — o AppBar já identifica
                  // a superfície; o CompareStage abre com o job (Assinar / Seu plano).
                  if (usage != null &&
                      ((widget.blockedFeature != null &&
                              widget.blockedFeature!.isNotEmpty) ||
                          widget.blockedCapability != null))
                    PaywallContextBanner(
                      usage: usage,
                      blockedFeatureLabel: widget.blockedFeature,
                      blockedCapability: widget.blockedCapability,
                      mute: mute,
                    ),
                  Expanded(
                    child: PaywallCompareStage(
                      fillViewport: true,
                      managementMode: managementMode,
                      plans: tabPlans,
                      currentPlan: currentPlan,
                      selectedPlan: selPlan,
                      comparisonRows: _compararTudo ? linhas : paywallLinhasDecisivas(linhas),
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
                                setState(() {
                                  _billingPeriod = period;
                                  _billingPeriodTouched = true;
                                });
                                _selectPlan(selPlan);
                              }
                              : null,
                      ink: ink,
                      mute: mute,
                      isDark: isDark,
                      line: line,
                    ),
                  ),
                  if (paywallLinhasDecisivas(linhas).length < linhas.length)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FxActionLink(
                        label:
                            _compararTudo
                                ? S.of(context).assinaturaVerMenos
                                : S.of(context).assinaturaVerTudo,
                        onTap:
                            () => setState(
                              () => _compararTudo = !_compararTudo,
                            ),
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
                          'Loja indisponível nesta sessão — use o botão abaixo para abrir ${subscriptionChannelWith(ChannelPreposition.artigo)} e gerenciar sua assinatura.',
                      ink: ink,
                      mute: mute,
                      isDark: isDark,
                    ),
                  ],
                  if (kIsWeb) ...[
                    const SizedBox(height: TokensStrip.s3),
                    _PaywallInlineNote(
                      icon: Icons.smartphone_outlined,
                      text: S.of(context).assinaturaWebLojasCelular,
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
