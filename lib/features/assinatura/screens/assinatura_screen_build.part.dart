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
    final planosAsync = ref.watch(planosProvider);
    final vitrineAsync = ref.watch(paywallVitrineProvider);
    final vitrine = vitrineAsync.valueOrNull;
    final trialDaysFromVitrine = vitrine?.trialDaysOffer;
    final vitrineComparison =
        vitrine?.effectiveComparisonRows ?? PaywallCatalog.comparisonRows;
    final featuresAsync = ref.watch(planoFeaturesProvider);

    final planos = planosAsync.valueOrNull;

    SubscriptionPlan? paywallNextTier;
    var paywallHasUpgradeAbove = false;
    String? enterpriseProRoiTag;
    if (planos != null && planos.isNotEmpty) {
      Plano? enterprisePlano;
      Plano? enterpriseProPlano;
      for (final p in planos) {
        final tier = subscriptionPlanFromApi(p.nome);
        if (tier == SubscriptionPlan.ENTERPRISE) enterprisePlano = p;
        if (tier == SubscriptionPlan.ENTERPRISE_PRO) enterpriseProPlano = p;
        final nextTier = paywallNextTier;
        if (tier.level > currentPlan.level &&
            (nextTier == null || tier.level > nextTier.level)) {
          paywallNextTier = tier;
        }
      }
      paywallHasUpgradeAbove = paywallNextTier != null;
      if (enterprisePlano != null && enterpriseProPlano != null) {
        final delta =
            enterpriseProPlano.precoMensal - enterprisePlano.precoMensal;
        if (delta > 0) {
          enterpriseProRoiTag = '+R\$ ${delta.toStringAsFixed(0)}/mês';
        }
      }
    }

    if (!_initialSelectionApplied && planos != null) {
      _selectedPlanName = _resolveInitialPlanSelection(
        currentPlan: currentPlan,
        deepLinkPlan: widget.initialPlan,
      );
      _initialSelectionApplied = true;
    }

    SubscriptionPlan selectedPlan = currentPlan;
    Plano? selectedBackendPlan;
    var isCurrentPlan = false;
    var isDowngrade = false;
    var ctaEnabled = false;
    var ctaLabel = 'Assinar';
    var ctaMode = _AssinaturaCtaMode.subscribe;
    String footnote = '';
    var showEnterpriseProStickySecondary = false;
    var hideScrollUpgradeLegal = false;

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
      hideScrollUpgradeLegal =
          currentPlan != SubscriptionPlan.FREE &&
          selectedPlan.level > currentPlan.level;
      showEnterpriseProStickySecondary =
          isCurrentPlan &&
          currentPlan == SubscriptionPlan.ENTERPRISE &&
          paywallHasUpgradeAbove &&
          paywallNextTier == SubscriptionPlan.ENTERPRISE_PRO &&
          subscriptionUsesNativeStore;

      if (_syncingPurchase) {
        ctaMode = _AssinaturaCtaMode.syncing;
        ctaLabel = 'Sincronizando assinatura...';
        ctaEnabled = false;
        footnote = 'Aguarde a confirmação da loja.';
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
        if (showEnterpriseProStickySecondary) {
          footnote = '';
        } else if (currentPlan == SubscriptionPlan.ENTERPRISE &&
            paywallHasUpgradeAbove &&
            paywallNextTier == SubscriptionPlan.ENTERPRISE_PRO &&
            subscriptionUsesNativeStore) {
          footnote =
              enterpriseProRoiTag != null
                  ? 'Enterprise Pro: Landing, Loja e Pose Coach · $enterpriseProRoiTag'
                  : 'Enterprise Pro desbloqueia Landing, Loja digital e Pose Coach.';
        } else {
          footnote = '';
        }
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
      } else if (selectedPlan == SubscriptionPlan.FREE) {
        ctaMode = _AssinaturaCtaMode.blocked;
        ctaLabel = 'Plano gratuito';
        ctaEnabled = false;
        footnote = 'O plano gratuito não requer assinatura.';
      } else {
        ctaMode = _AssinaturaCtaMode.subscribe;
        ctaEnabled =
            !_loadingCheckout &&
            (kIsWeb || !subscriptionUsesNativeStore || _storeAvailable);
        final trialDays =
            _trialStatus?.trialDaysOffer ?? trialDaysFromVitrine ?? 14;
        final trialOffer =
            selectedPlan == SubscriptionPlan.ENTERPRISE &&
            _trialStatus?.trialEligible == true;
        final isUpgrade = selectedPlan.level > currentPlan.level;
        final selectedLabel = PaywallCatalog.displayPlanName(selectedPlan);
        ctaLabel =
            trialOffer
                ? 'Começar $trialDays dias grátis — ${PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE)}'
                : isUpgrade
                ? 'Confirmar upgrade'
                : selectedPlan == SubscriptionPlan.ENTERPRISE_PRO
                ? 'Continuar com $selectedLabel'
                : selectedPlan == SubscriptionPlan.ENTERPRISE
                ? 'Continuar com $selectedLabel'
                : 'Continuar com ${PaywallCatalog.displayPlanName(SubscriptionPlan.PREMIUM)}';
        footnote =
            subscriptionUsesNativeStore
                ? (_billingPeriod == SubscriptionBillingPeriod.yearly
                    ? 'Cobrança anual com renovação automática. Cancele na loja quando quiser.'
                    : 'Cobrança mensal com renovação automática. Cancele na loja quando quiser.')
                : 'Checkout seguro via Mercado Pago. Ao continuar, você aceita os Termos e a Privacidade.';
      }
    }

    final trialOffer =
        selectedPlan == SubscriptionPlan.ENTERPRISE &&
        !isCurrentPlan &&
        _trialStatus?.trialEligible == true;
    final planSummary =
        planos == null
            ? null
            : isCurrentPlan
            ? '${PaywallCatalog.displayPlanName(currentPlan)} · Ativo'
            : selectedPlan.level > currentPlan.level
            ? 'Upgrade · ${PaywallCatalog.displayPlanName(selectedPlan)}'
            : null;

    final isUpgradeSelection =
        planos != null &&
        subscriptionPlanFromApi(
              _selectedPlanName ?? currentPlan.apiName,
            ).level >
            currentPlan.level;
    final stickyTierAccent =
        isUpgradeSelection && selectedPlan == SubscriptionPlan.ENTERPRISE_PRO
            ? PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO)
            : null;
    if (_paymentBlocked) {
      return FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Planos',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: const FxEmptyState(
          icon: 'alert-triangle',
          title: 'Dispositivo não seguro',
          subtitle:
              'Detectamos risco de jailbreak ou modo desenvolvedor. '
              'Por sua segurança, pagamentos estão desativados neste aparelho.',
        ),
      );
    }

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Planos',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
        actions: [
          Semantics(
            button: true,
            label: 'Cancelar assinatura',
            child: IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar assinatura',
              onPressed: () => context.push('/cancel-save'),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          selectedBackendPlan == null
              ? null
              : _AssinaturaStickyGlassBar(
                isDark: isDark,
                line: line,
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: _AssinaturaStickyFooter(
                    mode: ctaMode,
                    label: ctaLabel,
                    planSummary: planSummary,
                    footnote: footnote,
                    enabled: ctaEnabled,
                    loading: _loadingCheckout || _syncingPurchase,
                    trialHint: trialOffer,
                    showLegalConsent: ctaMode == _AssinaturaCtaMode.subscribe,
                    isUpgrade: isUpgradeSelection,
                    tierAccent: stickyTierAccent,
                    ink: ink,
                    mute: mute,
                    line: line,
                    primary: primary,
                    secondaryLabel:
                        showEnterpriseProStickySecondary
                            ? 'Ver Enterprise Pro'
                            : null,
                    onSecondary:
                        showEnterpriseProStickySecondary
                            ? _focusEnterpriseProUpgrade
                            : null,
                    onSubscribe:
                        () =>
                            _startCheckout(selectedPlan, selectedBackendPlan!),
                    onManage: _openSubscriptionManagement,
                    onRestore:
                        hideScrollUpgradeLegal && subscriptionUsesNativeStore
                            ? _restorePurchases
                            : null,
                    restoringPurchases: _restoringPurchases,
                    onBillingDetails:
                        hideScrollUpgradeLegal
                            ? () => PaywallUpgradeLegalCompact.showBillingSheet(
                              context,
                              ink: ink,
                              mute: mute,
                              primary: primary,
                              showStoreBillingNote: subscriptionUsesNativeStore,
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
      body: planosAsync.when(
        loading: () => const PaywallLoadingSkeleton(),
        error:
            (error, _) => FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: friendlyError(error),
              onRetry: () {
                ref.invalidate(planosProvider);
                ref.invalidate(paywallVitrineProvider);
              },
              title: 'Não foi possível carregar os planos',
            ),
        data: (planosList) {
          if (planosList.isEmpty) {
            return FxEmptyState(
              icon: 'dollar-sign',
              title: 'Nenhum plano disponível',
              subtitle: 'Tente novamente em instantes.',
              action: FxEmptyAction(
                label: 'Tentar de novo',
                onTap: () {
                  ref.invalidate(planosProvider);
                  ref.invalidate(paywallVitrineProvider);
                },
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
            vitrineComparison: vitrineComparison,
            trialDaysFromVitrine: trialDaysFromVitrine,
            paywallNextTier: paywallNextTier,
            paywallHasUpgradeAbove: paywallHasUpgradeAbove,
            enterpriseProRoiTag: enterpriseProRoiTag,
            showEnterpriseProStickySecondary: showEnterpriseProStickySecondary,
          );
        },
      ),
    );
  }
}
