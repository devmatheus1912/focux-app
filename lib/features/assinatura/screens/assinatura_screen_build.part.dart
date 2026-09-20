part of 'assinatura_screen.dart';

extension AssinaturaScreenBuild on _AssinaturaScreenState {
  Widget buildAssinaturaScreen(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final primary = BrandPalette.softened(theme.colorScheme.primary);

    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final homeAsync = ref.watch(paywallHomeProvider);
    final home = homeAsync.valueOrNull;
    final vitrine = home?.vitrine;
    final meFromHome = home?.me;
    final AsyncValue<PlanoFeatures?> featuresAsync;
    if (meFromHome != null) {
      featuresAsync = AsyncValue<PlanoFeatures?>.data(meFromHome);
    } else {
      featuresAsync = ref
          .watch(planoFeaturesProvider)
          .when(
            data: (value) => AsyncValue<PlanoFeatures?>.data(value),
            loading: () => const AsyncValue<PlanoFeatures?>.loading(),
            error:
                (error, stack) =>
                    AsyncValue<PlanoFeatures?>.error(error, stack),
          );
    }

    final planos = home?.planos;

    SubscriptionPlan? paywallNextTier;
    var paywallHasUpgradeAbove = false;
    if (planos != null && planos.isNotEmpty) {
      for (final p in planos) {
        final tier = subscriptionPlanFromApi(p.nome);
        final nextTier = paywallNextTier;
        if (tier.level > currentPlan.level &&
            (nextTier == null || tier.level > nextTier.level)) {
          paywallNextTier = tier;
        }
      }
      paywallHasUpgradeAbove = paywallNextTier != null;
    }

    ref.listen(paywallHomeProvider, (previous, next) {
      next.whenData((home) {
        final me = home.me;
        if (me != null) {
          ref.read(planoFeaturesProvider.notifier).seedFromHome(me);
        }
        if (_initialSelectionApplied || home.planos.isEmpty) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _initialSelectionApplied) return;
          final billingPlan = subscriptionPlanFromApi(
            ref.read(perfilProvider).valueOrNull?.plano,
          );
          setState(() {
            _selectedPlanName = _resolveInitialPlanSelection(
              currentPlan: billingPlan,
              deepLinkPlan: widget.initialPlan,
            );
            _initialSelectionApplied = true;
          });
        });
      });
    });

    SubscriptionPlan selectedPlan = currentPlan;
    Plano? selectedBackendPlan;
    var isCurrentPlan = false;
    var isDowngrade = false;
    var ctaEnabled = false;
    var ctaLabel = 'Assinar';
    var ctaMode = _AssinaturaCtaMode.subscribe;
    String footnote = '';

    if (planos != null && planos.isNotEmpty) {
      selectedPlan = subscriptionPlanFromApi(
        _selectedPlanName ?? currentPlan.apiName,
      );
      selectedBackendPlan = planos.firstWhere(
        (plan) => subscriptionPlanFromApi(plan.nome) == selectedPlan,
        orElse: () => planos.first,
      );
      isCurrentPlan = selectedPlan == currentPlan;
      isDowngrade = selectedPlan.level < currentPlan.level;

      if (_syncingPurchase) {
        ctaMode = _AssinaturaCtaMode.syncing;
        ctaLabel = 'Sincronizando assinatura...';
        ctaEnabled = false;
        footnote = 'Aguarde a confirmação da loja.';
      } else if (selectedPlan == SubscriptionPlan.FREE) {
        ctaMode = _AssinaturaCtaMode.goHome;
        ctaLabel = 'Continuar no FREE';
        ctaEnabled = true;
        footnote =
            'Sem cartão. Você já pode usar a Home e os recursos do plano gratuito.';
      } else if (isCurrentPlan) {
        ctaMode =
            subscriptionUsesNativeStore
                ? _AssinaturaCtaMode.manageStore
                : _AssinaturaCtaMode.currentPlan;
        ctaLabel =
            subscriptionUsesNativeStore
                ? 'Gerenciar assinatura na loja'
                : 'Plano atual';
        ctaEnabled = subscriptionUsesNativeStore && !_loadingCheckout;
        footnote = '';
      } else if (isDowngrade) {
        ctaMode =
            subscriptionUsesNativeStore
                ? _AssinaturaCtaMode.manageStore
                : _AssinaturaCtaMode.blocked;
        ctaLabel =
            subscriptionUsesNativeStore
                ? 'Abrir assinaturas do dispositivo'
                : 'Plano superior necessário';
        ctaEnabled = subscriptionUsesNativeStore;
        footnote =
            subscriptionUsesNativeStore
                ? 'Downgrade só nas assinaturas do dispositivo. Você pode perder recursos do plano atual.'
                : '';
      } else {
        ctaMode = _AssinaturaCtaMode.subscribe;
        ctaEnabled =
            !_loadingCheckout &&
            (kIsWeb || !subscriptionUsesNativeStore || _storeAvailable);
        final trialOffer = paywallShowsMaxPlanTrial(
          selected: selectedPlan,
          current: currentPlan,
          trialEligible: _trialStatus?.trialEligible,
        );
        const trialDays = kPaywallMaxPlanTrialDays;
        final isUpgrade = selectedPlan.level > currentPlan.level;
        final selectedLabel = PaywallCatalog.displayPlanName(selectedPlan);
        ctaLabel =
            trialOffer
                ? 'Começar $trialDays dias grátis'
                : isUpgrade
                ? 'Confirmar upgrade'
                : 'Continuar com $selectedLabel';
        footnote =
            trialOffer
                ? ''
                : subscriptionUsesNativeStore
                ? (_billingPeriod == SubscriptionBillingPeriod.yearly
                    ? 'Anual · 2 meses grátis. Cancele na loja quando quiser.'
                    : 'Renova na loja. Cancele quando quiser.')
                : 'Checkout seguro via Mercado Pago.';
      }
    }

    final trialOffer = paywallShowsMaxPlanTrial(
      selected: selectedPlan,
      current: currentPlan,
      trialEligible: _trialStatus?.trialEligible,
    );
    final selectedStorePrice =
        selectedBackendPlan == null
            ? null
            : _productDetails[SubscriptionProducts.productIdFor(
                  selectedPlan,
                  _billingPeriod,
                )]
                ?.price;
    final selectedPrice =
        selectedBackendPlan == null
            ? null
            : buildPaywallPriceCopy(
              precoMensal: selectedBackendPlan.precoMensal,
              precoAnual: selectedBackendPlan.precoAnual,
              precoAnualMensalEquiv:
                  selectedBackendPlan.equivMensalNoAnual ??
                  selectedBackendPlan.precoAnualMensalEquiv,
              labelDescontoAnual: selectedBackendPlan.labelDescontoAnual,
              labelEconomiaAnual: selectedBackendPlan.labelEconomiaAnual,
              period: _billingPeriod,
              storePrice: selectedStorePrice,
            );
    final planSummary =
        planos == null || !isCurrentPlan
            ? null
            : '${PaywallCatalog.displayPlanName(currentPlan)} · Ativo';

    final isUpgradeSelection =
        planos == null
            ? false
            : subscriptionPlanFromApi(
                  _selectedPlanName ?? currentPlan.apiName,
                ).level >
                currentPlan.level;
    if (planos != null &&
        ctaMode == _AssinaturaCtaMode.subscribe &&
        !_syncingPurchase) {
      ctaLabel = paywallStickyCtaLabel(
        trialOffer: trialOffer,
        isUpgrade: isUpgradeSelection,
        planName: PaywallCatalog.displayPlanName(selectedPlan),
        pricePrimary: selectedPrice?.primary,
      );
      if (trialOffer) {
        final price = selectedPrice?.primary.trim();
        if (price != null && price.isNotEmpty && price != 'Grátis') {
          footnote = 'Depois $price. Cancele quando quiser.';
        }
      }
    }
    if (_enterprisePreview != null) {
      final note = _enterprisePreviewFootnote(
        _enterprisePreview!,
        currentPlan,
        selectedPlan,
      );
      if (note != null) footnote = note;
    }
    final stickyTierAccent =
        isUpgradeSelection && selectedPlan == SubscriptionPlan.ENTERPRISE
            ? PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE)
            : null;
    if (_paymentBlocked) {
      // Ainda mostra Planos — só checkout fica bloqueado (DeviceGuard).
      ctaMode = _AssinaturaCtaMode.blocked;
      ctaLabel = 'Compras bloqueadas no aparelho';
      ctaEnabled = false;
      footnote =
          'Opções de desenvolvedor ou root detectadas. '
          'Desligue para testar compras. Conta FREE segue ativa.';
    }

    // Sem tier acima (ex.: Enterprise): superfície de gestão, não paywall.
    final managementMode =
        currentPlan != SubscriptionPlan.FREE && !paywallHasUpgradeAbove;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: managementMode ? 'Assinatura' : 'Planos',
        subtitle: FxHubFreshness.fromFetchedAt(_paywallFetchedAt),
        onBack: () {
          FxKeyboardDismissScope.dismiss();
          safePopOrGo(context, '/perfil');
        },
        actions: [
          if (currentPlan != SubscriptionPlan.FREE)
            Semantics(
              button: true,
              label: 'Cancelar assinatura',
              child: TextButton(
                onPressed: () => context.push('/cancel-save'),
                child: Text(
                  'Cancelar',
                  style: TokensStrip.body(color: primary).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          selectedBackendPlan == null
              ? null
              : FxContentWidthLimiter(
                expandHeight: false,
                child: AnimatedSwitcher(
                  duration:
                      TokensStrip.prefersReducedMotion(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey('${ctaMode.name}-$ctaLabel'),
                    child: _AssinaturaStickyGlassBar(
                      isDark: isDark,
                      line: line,
                      child: SafeArea(
                        minimum: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          TokensStrip.s2,
                          TokensStrip.s5,
                          TokensStrip.s2,
                        ),
                        child: _AssinaturaStickyFooter(
                          mode: ctaMode,
                          label: ctaLabel,
                          planSummary: planSummary,
                          footnote: footnote,
                          enabled: ctaEnabled,
                          loading: _loadingCheckout || _syncingPurchase,
                          showLegalConsent:
                              ctaMode == _AssinaturaCtaMode.subscribe,
                          isUpgrade: isUpgradeSelection,
                          tierAccent: stickyTierAccent,
                          ink: ink,
                          mute: mute,
                          primary: primary,
                          onSubscribe:
                              () => _startCheckout(
                                selectedPlan,
                                selectedBackendPlan!,
                              ),
                          onManage:
                              ctaMode == _AssinaturaCtaMode.goHome
                                  ? () => context.go('/dashboard/personal')
                                  : _openSubscriptionManagement,
                          onRestore:
                              ctaMode == _AssinaturaCtaMode.manageStore &&
                                      subscriptionUsesNativeStore
                                  ? _restorePurchases
                                  : null,
                          restoringPurchases: _restoringPurchases,
                          onBillingDetails:
                              ctaMode == _AssinaturaCtaMode.manageStore
                                  ? () => _showAssinaturaTermosSheet(
                                        context,
                                        mute: mute,
                                        primary: primary,
                                        showStoreBillingNote:
                                            subscriptionUsesNativeStore,
                                        restoring: _restoringPurchases,
                                        onRestore:
                                            subscriptionUsesNativeStore
                                                ? _restorePurchases
                                                : null,
                                      )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      body: homeAsync.when(
        loading: () => const PaywallLoadingSkeleton(),
        error:
            (error, _) => FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: friendlyError(error),
              onRetry: () {
                ref.invalidate(paywallHomeProvider);
              },
              title: 'Não foi possível carregar os planos',
            ),
        data: (home) {
          final planosList = home.planos;
          if (planosList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FxEmptyState(
                      icon: 'dollar-sign',
                      title: 'Planos em sincronização',
                      subtitle:
                          'Não carregamos o catálogo agora. Atualize — o Pro destrava cobrança PIX, IA e landing pública.',
                      action: FxEmptyAction(
                        label: 'Tentar de novo',
                        onTap: () {
                          ref.invalidate(paywallHomeProvider);
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => FocuxLegal.openSupport(),
                      child: Text(
                        'Falar com suporte',
                        style: TextStyle(
                          color: mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return buildPaywallPlansScroll(
            planosList: planosList,
            currentPlan: currentPlan,
            ink: ink,
            mute: mute,
            line: line,
            primary: primary,
            isDark: isDark,
            featuresAsync: featuresAsync,
            vitrine: vitrine,
            paywallNextTier: paywallNextTier,
            paywallHasUpgradeAbove: paywallHasUpgradeAbove,
            managementMode: managementMode,
          );
        },
      ),
    );
  }
}
