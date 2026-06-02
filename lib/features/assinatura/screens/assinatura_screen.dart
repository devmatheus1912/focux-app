import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/legal/focux_legal.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/subscription/utils/plano_ia_limits.dart';
import '../../../features/growth/utils/migracao_foto_limits.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../../../features/subscription/services/iap_service.dart';
import '../../../features/subscription/store_subscription_policy.dart';
import '../../../features/subscription/subscription_products.dart';

import '../data/plano.dart';
import '../providers/assinatura_provider.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../planos/paywall/paywall_components.dart';
import '../../subscription/plan_entitlements.dart';
import '../services/subscription_biometric_gate.dart';
import '../services/subscription_device_guard.dart';
import 'assinatura_review_screen.dart';
import 'assinatura_success_screen.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';

part 'paywall_layout.dart';

/// Preview de upgrade quando há dados úteis para o tier selecionado.
bool _enterprisePreviewIsInformative(
  EnterpriseUpgradePreview preview,
  SubscriptionPlan currentPlan,
  SubscriptionPlan selectedPlan,
) {
  if (selectedPlan.level <= currentPlan.level) return false;
  if (preview.planoDestino != selectedPlan) return false;
  return preview.cobrancaImediata ||
      preview.diasRestantes > 0 ||
      preview.valorProporcional > 0 ||
      preview.diferencaDiaria > 0;
}

bool _shouldLoadEnterprisePreview(
  SubscriptionPlan currentPlan,
  SubscriptionPlan selectedPlan,
) {
  if (selectedPlan.level <= currentPlan.level) return false;
  return selectedPlan == SubscriptionPlan.ENTERPRISE ||
      (currentPlan == SubscriptionPlan.ENTERPRISE &&
          selectedPlan == SubscriptionPlan.ENTERPRISE_PRO);
}

/// Plano pré-selecionado: atual por padrão; deep link só se for upgrade válido.
String _resolveInitialPlanSelection({
  required SubscriptionPlan currentPlan,
  String? deepLinkPlan,
}) {
  final deep = deepLinkPlan?.trim().toUpperCase();
  if (deep != null && deep.isNotEmpty) {
    final target = subscriptionPlanFromApi(deep);
    if (currentPlan == SubscriptionPlan.FREE ||
        target.level > currentPlan.level) {
      return target.apiName;
    }
  }
  if (currentPlan != SubscriptionPlan.FREE) return currentPlan.apiName;
  return deep ?? SubscriptionPlan.PREMIUM.apiName;
}

/// Trial só para quem ainda pode assinar Enterprise (não assinante atual).
bool _shouldShowEnterpriseTrialCard(
  SubscriptionPlan selectedPlan,
  SubscriptionPlan currentPlan,
  TrialStatus? trialStatus,
) {
  if (selectedPlan != SubscriptionPlan.ENTERPRISE) return false;
  if (currentPlan == SubscriptionPlan.ENTERPRISE) return false;
  if (trialStatus?.trialAtivo == true) return true;
  return trialStatus?.trialEligible == true;
}

class AssinaturaScreen extends ConsumerStatefulWidget {
  final String? initialPlan;
  final String? source;
  final String? blockedFeature;
  final String? blockedCapability;

  const AssinaturaScreen({
    super.key,
    this.initialPlan,
    this.source,
    this.blockedFeature,
    this.blockedCapability,
  });

  @override
  ConsumerState<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends ConsumerState<AssinaturaScreen> {
  final Set<String> _handledPurchases = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final ScrollController _paywallScrollController = ScrollController();
  final GlobalKey _paywallPlanosKey = GlobalKey();
  final GlobalKey _paywallUpgradeKey = GlobalKey();
  final GlobalKey _paywallCompareKey = GlobalKey();
  final GlobalKey _paywallLegalKey = GlobalKey();
  final GlobalKey _paywallUpgradeTargetKey = GlobalKey();

  String? _selectedPlanName;
  bool _loadingCheckout = false;
  bool _syncingPurchase = false;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _productDetails = const {};
  EnterpriseUpgradePreview? _enterprisePreview;
  bool _enterprisePreviewRequested = false;
  bool _initialSelectionApplied = false;

  // Trial
  TrialStatus? _trialStatus;
  bool _loadingTrial = false;
  bool _restoringPurchases = false;
  bool _paymentBlocked = false;
  bool _upgradeOffersExpanded = false;
  SubscriptionBillingPeriod _billingPeriod = SubscriptionBillingPeriod.yearly;

  Future<void> _checkDeviceSecurity() async {
    if (kIsWeb) return;
    final compromised = await SubscriptionDeviceGuard.isCompromised();
    if (mounted && compromised) setState(() => _paymentBlocked = true);
  }

  Future<void> _restorePurchases() async {
    if (_restoringPurchases || !subscriptionUsesNativeStore) return;

    setState(() => _restoringPurchases = true);
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(content: Text('Verificando compras anteriores...')),
    );

    try {
      final result = await ref.read(iapServiceProvider).restoreAndVerifyPurchases(
        onVerified: (_, __) async {
          ref.invalidate(perfilProvider);
          ref.invalidate(planoFeaturesProvider);
        },
      );
      ref.invalidate(perfilProvider);
      ref.invalidate(planoFeaturesProvider);

      if (!mounted) return;

      if (!result.storeAvailable) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('A loja do dispositivo não está disponível.')),
        );
        return;
      }

      if (result.hasVerifiedPurchases) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Compras restauradas com sucesso.')),
        );
        return;
      }

      if (result.errors.isNotEmpty) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(result.errors.first.message)),
        );
        return;
      }

      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Nenhuma compra anterior encontrada.')),
      );
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text('Erro ao restaurar compras: $error')),
      );
    } finally {
      if (mounted) setState(() => _restoringPurchases = false);
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(
      ProductEvents.paywallOpened,
      props: {
        if (widget.source != null) 'source': widget.source,
        if (widget.initialPlan != null) 'highlight': widget.initialPlan,
      },
    );
    _selectedPlanName = null;
    if (!kIsWeb) {
      _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (Object error) {
          _finishPurchaseFlowWithError('Erro ao acompanhar a compra: $error');
        },
      );
    }
    _initializeStore();
    _loadTrialStatus();
    _checkDeviceSecurity();
    if (widget.initialPlan?.trim().toUpperCase() == 'ENTERPRISE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadEnterprisePreview();
      });
    }
  }

  Future<void> _openSubscriptionManagement() async {
    HapticFeedback.lightImpact();
    if (subscriptionUsesNativeStore) {
      final ok = await openNativeSubscriptionManagement();
      if (!mounted) return;
      if (!ok) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(
            content: Text(
              'Não foi possível abrir as assinaturas do dispositivo.',
            ),
          ),
        );
      }
      return;
    }
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(
        content: Text('Gerencie sua assinatura na área de cobrança da web.'),
      ),
    );
  }

  void _scrollToPaywallSection(PaywallScrollTarget target) {
    if (target == PaywallScrollTarget.features ||
        target == PaywallScrollTarget.roi) {
      HapticFeedback.selectionClick();
      if (FocuxLegal.plansMarketingWebLive) {
        unawaited(FocuxLegal.openPlansMarketing());
      } else {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(
            content: Text(
              'Comparação detalhada (tabela, ROI e features) no site em breve.',
            ),
          ),
        );
      }
      return;
    }

    final GlobalKey anchorKey = switch (target) {
      PaywallScrollTarget.planos || PaywallScrollTarget.seuPlano =>
        _paywallPlanosKey,
      PaywallScrollTarget.upgrade => _paywallUpgradeKey,
      PaywallScrollTarget.comparar => _paywallCompareKey,
      PaywallScrollTarget.legal => _paywallLegalKey,
      PaywallScrollTarget.features || PaywallScrollTarget.roi =>
        _paywallPlanosKey,
    };

    final ctx = anchorKey.currentContext;
    if (ctx == null) return;
    HapticFeedback.selectionClick();
    final motion = TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    Scrollable.ensureVisible(
      ctx,
      duration: motion,
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  void _scrollToUpgradeTargetCard() {
    final ctx = _paywallUpgradeTargetKey.currentContext;
    if (ctx == null) return;
    final motion = TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    Scrollable.ensureVisible(
      ctx,
      duration: motion,
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  void _handleDowngradeTierTap() {
    HapticFeedback.lightImpact();
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(
        content: Text(
          'Downgrade e cancelamento só nas assinaturas do ${subscriptionChannelLabel()}.',
        ),
        action:
            subscriptionUsesNativeStore
                ? SnackBarAction(
                  label: 'Abrir',
                  onPressed: _openSubscriptionManagement,
                )
                : null,
      ),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _paywallScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrialStatus() async {
    if (mounted) setState(() => _loadingTrial = true);
    try {
      final status =
          await PlanosRepository(ref.read(apiClientProvider)).getTrialStatus();
      if (mounted) {
        setState(() {
          _trialStatus = status;
          _loadingTrial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTrial = false);
    }
  }

  Future<void> _initializeStore() async {
    if (kIsWeb) {
      if (mounted) setState(() => _storeAvailable = false);
      return;
    }

    final available = await InAppPurchase.instance.isAvailable();
    if (!mounted) return;

    setState(() => _storeAvailable = available);

    if (!available) return;

    final response = await InAppPurchase.instance.queryProductDetails(
      SubscriptionProducts.allStoreProductIds,
    );

    if (!mounted) return;

    setState(() {
      _productDetails = {
        for (final item in response.productDetails) item.id: item,
      };
    });
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            if (mounted) setState(() => _loadingCheckout = true);
            break;
          case PurchaseStatus.error:
            _finishPurchaseFlowWithError(
              purchase.error?.message ?? 'Falha ao concluir a compra.',
            );
            break;
          case PurchaseStatus.canceled:
            if (mounted) {
              setState(() {
                _loadingCheckout = false;
                _syncingPurchase = false;
              });
            }
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _syncPurchase(purchase);
            break;
        }
      } finally {
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _syncPurchase(PurchaseDetails purchase) async {
    final purchaseKey = [
      purchase.productID,
      purchase.purchaseID ?? 'sem-id',
      purchase.transactionDate ?? 'sem-data',
    ].join('|');

    if (_handledPurchases.contains(purchaseKey)) return;

    final purchasedPlan = _planForProductId(purchase.productID);
    if (purchasedPlan == null) {
      _finishPurchaseFlowWithError('Produto recebido não é suportado.');
      return;
    }

    _handledPurchases.add(purchaseKey);

    if (mounted) {
      setState(() {
        _loadingCheckout = false;
        _syncingPurchase = true;
        _selectedPlanName = purchasedPlan.apiName;
      });
    }

    try {
      await ref.read(iapServiceProvider).verifyPurchase(purchase);

      ref.invalidate(perfilProvider);
      ref.invalidate(planoFeaturesProvider);
      ref.invalidate(planosProvider);

      if (!mounted) return;

      AnalyticsService.instance.track(
        ProductEvents.checkoutCompleted,
        props: {
          'plan_id': purchasedPlan.apiName,
          if (purchase.purchaseID != null) 'transaction_id': purchase.purchaseID,
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AssinaturaSuccessScreen(
            plan: purchasedPlan,
            transactionId: purchase.purchaseID,
          ),
        ),
      );
      if (mounted) safePopOrGo(context, '/dashboard/personal');
    } catch (error) {
      _handledPurchases.remove(purchaseKey);
      _finishPurchaseFlowWithError(
        'Não foi possível sincronizar a assinatura: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingPurchase = false;
          _loadingCheckout = false;
        });
      }
    }
  }

  SubscriptionPlan? _planForProductId(String productId) =>
      SubscriptionProducts.planForProductId(productId);

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    if (_selectedPlanName == plan.apiName) return;

    final perfil = ref.read(perfilProvider).valueOrNull;
    final current = subscriptionPlanFromApi(perfil?.plano);
    if (plan.level < current.level) {
      _handleDowngradeTierTap();
      return;
    }

    AnalyticsService.instance.track(
      ProductEvents.paywallPlanSelected,
      props: {'plan_id': plan.apiName},
    );

    setState(() {
      _selectedPlanName = plan.apiName;
      if (!_shouldLoadEnterprisePreview(current, plan)) {
        _enterprisePreview = null;
      }
      _enterprisePreviewRequested = false;
    });

    if (_shouldLoadEnterprisePreview(current, plan)) {
      await _loadEnterprisePreview();
    }
  }

  Future<void> _loadEnterprisePreview() async {
    try {
      final preview =
          await PlanosRepository(
            ref.read(apiClientProvider),
          ).previewEnterpriseUpgrade();
      if (!mounted) return;
      setState(() => _enterprisePreview = preview);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enterprisePreview = null);
    }
  }

  Future<void> _startCheckout(SubscriptionPlan plan, Plano backendPlan) async {
    if (_loadingCheckout || _syncingPurchase) return;

    if (!kIsWeb &&
        subscriptionUsesNativeStore &&
        !_storeAvailable) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Loja do dispositivo indisponível. Tente novamente em instantes.',
          ),
        ),
      );
      return;
    }

    AnalyticsService.instance.track(
      ProductEvents.paywallCtaTapped,
      props: {
        'plan_id': plan.apiName,
        'billing_period': _billingPeriod.name,
        if (widget.source != null) 'source': widget.source,
      },
    );

    if (!kIsWeb && subscriptionUsesNativeStore) {
      final biometricOk = await SubscriptionBiometricGate.confirmSubscription(
        planName: plan.apiName,
      );
      if (!mounted || !biometricOk) return;

      final product = _productDetails[
        SubscriptionProducts.productIdFor(plan, _billingPeriod)];
      final priceDisplay = _formatPrice(
        backendPlan,
        product,
        _billingPeriod,
      );
      final trialNote =
          plan == SubscriptionPlan.ENTERPRISE &&
                  _trialStatus?.trialEligible == true
              ? 'Teste introdutório pode ser aplicado pela loja ao assinar.'
              : null;
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AssinaturaReviewScreen(
            plan: plan,
            billingPeriod: _billingPeriod,
            priceDisplay: priceDisplay,
            trialNote: trialNote,
          ),
        ),
      );
      if (!mounted || confirmed != true) return;
      AnalyticsService.instance.track(
        ProductEvents.checkoutStarted,
        props: {'plan_id': plan.apiName, 'billing_period': _billingPeriod.name},
      );
    }

    if (kIsWeb) {
      setState(() => _loadingCheckout = true);
      try {
        final checkoutUrl = await ref
            .read(assinaturaRepositoryProvider)
            .criarPreferencia(backendPlan.id);
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, webOnlyWindowName: '_self');
      } catch (error) {
        _finishPurchaseFlowWithError('Erro ao gerar checkout web: $error');
      }
      return;
    }

    if (!_storeAvailable) {
      _finishPurchaseFlowWithError(
        'A loja de aplicativos não está disponível neste dispositivo.',
      );
      return;
    }

    final productId = SubscriptionProducts.productIdFor(plan, _billingPeriod);
    if (productId.isEmpty) {
      _finishPurchaseFlowWithError(
        'Plano selecionado não possui produto válido.',
      );
      return;
    }

    ProductDetails? product = _productDetails[productId];
    if (product == null) {
      final response = await InAppPurchase.instance.queryProductDetails({
        productId,
      });
      if (!mounted) return;
      if (response.productDetails.isEmpty) {
        _finishPurchaseFlowWithError(
          'Produto ainda não configurado na loja para este plano.',
        );
        return;
      }
      product = response.productDetails.first;
      setState(
        () => _productDetails = {..._productDetails, productId: product!},
      );
    }

    setState(() => _loadingCheckout = true);

    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      _finishPurchaseFlowWithError('Erro ao iniciar a compra na loja: $error');
    }
  }

  void _finishPurchaseFlowWithError(String message) {
    AnalyticsService.instance.track(
      ProductEvents.checkoutFailed,
      props: {'error_message': message},
    );
    if (!mounted) return;
    setState(() {
      _loadingCheckout = false;
      _syncingPurchase = false;
    });
    FeedbackHelper.showSnackBar(context, SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final primary = theme.colorScheme.primary;

    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final planosAsync = ref.watch(planosProvider);
    final vitrineAsync = ref.watch(paywallVitrineProvider);
    final vitrine = vitrineAsync.valueOrNull;
    final trialDaysFromVitrine = vitrine?.trialDaysOffer;
    final vitrineComparison = vitrine?.effectiveComparisonRows ?? PaywallCatalog.comparisonRows;
    final featuresAsync = ref.watch(planoFeaturesProvider);

    final planos = planosAsync.valueOrNull;

    SubscriptionPlan? paywallNextTier;
    var paywallHasUpgradeAbove = false;
    double? enterpriseProMonthlyDelta;
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
        final delta = enterpriseProPlano.precoMensal - enterprisePlano.precoMensal;
        if (delta > 0) {
          enterpriseProMonthlyDelta = delta;
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
        if (currentPlan == SubscriptionPlan.ENTERPRISE &&
            paywallHasUpgradeAbove &&
            paywallNextTier == SubscriptionPlan.ENTERPRISE_PRO &&
            subscriptionUsesNativeStore) {
          footnote = enterpriseProRoiTag != null
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
        ctaLabel = trialOffer
            ? 'Começar $trialDays dias grátis — ${PaywallCatalog.displayPlanName(SubscriptionPlan.ENTERPRISE)}'
            : isUpgrade
            ? 'Fazer upgrade para $selectedLabel'
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
    final planSummary = planos == null
        ? null
        : isCurrentPlan
        ? '${PaywallCatalog.displayPlanName(currentPlan)} · Ativo'
        : selectedPlan.level > currentPlan.level
        ? 'Upgrade · ${PaywallCatalog.displayPlanName(selectedPlan)}'
        : null;

    final isUpgradeSelection =
        planos != null &&
        subscriptionPlanFromApi(_selectedPlanName ?? currentPlan.apiName).level >
            currentPlan.level;
    final stickyTierAccent = isUpgradeSelection &&
            selectedPlan == SubscriptionPlan.ENTERPRISE_PRO
        ? PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO)
        : null;
    final showEnterpriseProStickySecondary =
        isCurrentPlan &&
        currentPlan == SubscriptionPlan.ENTERPRISE &&
        paywallHasUpgradeAbove &&
        paywallNextTier == SubscriptionPlan.ENTERPRISE_PRO &&
        subscriptionUsesNativeStore;

    if (_paymentBlocked) {
      return FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Planos',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 48, color: primary),
              const SizedBox(height: 16),
              Text(
                'Dispositivo não seguro',
                textAlign: TextAlign.center,
                style: TokensStrip.h2(color: ink),
              ),
              const SizedBox(height: 10),
              Text(
                'Detectamos risco de jailbreak ou modo desenvolvedor. '
                'Por sua segurança, pagamentos estão desativados neste aparelho.',
                textAlign: TextAlign.center,
                style: TokensStrip.bodyMuted(color: mute),
              ),
            ],
          ),
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
                    secondaryLabel: showEnterpriseProStickySecondary
                        ? 'Ver Enterprise Pro'
                        : null,
                    onSecondary: showEnterpriseProStickySecondary
                        ? () {
                            HapticFeedback.selectionClick();
                            _selectPlan(SubscriptionPlan.ENTERPRISE_PRO);
                          }
                        : null,
                    onSubscribe:
                        () => _startCheckout(
                          selectedPlan,
                          selectedBackendPlan!,
                        ),
                    onManage: _openSubscriptionManagement,
                  ),
                ),
              ),
      body: planosAsync.when(
        loading: () => const PaywallLoadingSkeleton(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Não foi possível carregar os planos.', style: TextStyle(color: mute)),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center, style: TokensStrip.bodyMuted(color: mute)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(planosProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (planosList) {
          final sortedPlans = [...planosList]..sort(
            (a, b) => subscriptionPlanFromApi(
              a.nome,
            ).level.compareTo(subscriptionPlanFromApi(b.nome).level),
          );
          final paid =
              sortedPlans
                  .where(
                    (p) =>
                        subscriptionPlanFromApi(p.nome) !=
                        SubscriptionPlan.FREE,
                  )
                  .toList();

          if (paid.isEmpty) {
            return Center(
              child: Text(
                'Nenhum plano pago disponível no momento.',
                style: TextStyle(color: mute),
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

          final usage = featuresAsync.valueOrNull == null
              ? null
              : PlanEntitlements.snapshotFrom(
                plano: featuresAsync.value!.plano,
                alunosAtivos: featuresAsync.value!.alunosAtivos,
                limiteAlunos: featuresAsync.value!.limiteAlunos,
                iaUsadaMes: featuresAsync.value!.iaUsadaMes,
                limiteIaMensal: featuresAsync.value!.limiteIaMensal,
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
                    upgradeOffersExpanded: _upgradeOffersExpanded || isUpgradeTargetSelected,
                    upgradeTargetSelected: isUpgradeTargetSelected,
                  ),
                if (isAcquisition)
                  PaywallQuickNav(
                    primary: primary,
                    ink: isDark ? EagleTokens.darkInk : const Color(0xFF081012),
                    onSectionTap: _scrollToPaywallSection,
                  )
                else if (!usePlanStudio)
                  PaywallSubscriberQuickNav(
                    primary: primary,
                    ink: isDark ? EagleTokens.darkInk : const Color(0xFF081012),
                    onSectionTap: _scrollToPaywallSection,
                  ),
                if (usage != null)
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
                  final visiblePlans = currentPlan == SubscriptionPlan.FREE
                      ? sortedPlans
                      : sortedPlans
                          .where(
                            (p) =>
                                subscriptionPlanFromApi(p.nome) !=
                                SubscriptionPlan.FREE,
                          )
                          .toList();

                  final hasUpgradeAbove = visiblePlans.any(
                    (p) =>
                        subscriptionPlanFromApi(p.nome).level >
                        currentPlan.level,
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
                    final monthlyProduct = _productDetails[
                      SubscriptionProducts.productIdFor(
                        plan,
                        SubscriptionBillingPeriod.monthly,
                      )];
                    final annualProduct = _productDetails[
                      SubscriptionProducts.productIdFor(
                        plan,
                        SubscriptionBillingPeriod.yearly,
                      )];
                    final monthlyPrice = monthlyProduct != null
                        ? monthlyProduct.price.replaceAll(RegExp(r'/.*'), '')
                        : paywallMonthlyFromPlano(plano);
                    final annualPrice = annualProduct != null
                        ? annualProduct.price.replaceAll(RegExp(r'/.*'), '')
                        : paywallAnnualMonthlyEquiv(plano);
                    final storeOk =
                        kIsWeb || !subscriptionUsesNativeStore || _storeAvailable;
                    final isUpgradeTier =
                        !lockedDowngrade &&
                        plan.level > currentPlan.level &&
                        !isAcquisition;
                    final upsellHighlights = isUpgradeTier
                        ? _paywallUpgradeGains(
                            currentBackend,
                            currentPlan,
                            plano,
                            plan,
                          ).map((r) => r.label).take(3).toList()
                        : const <String>[];
                    final nestedInAccordion =
                        plan != currentPlan || lockedDowngrade;
                    final cardKey = isUpgradeTier && plan == selPlan
                        ? _paywallUpgradeTargetKey
                        : null;
                    return PaywallRichPlanCard(
                      key: cardKey,
                      plano: plano,
                      plan: plan,
                      embeddedInStudio: usePlanStudio && !lockedDowngrade,
                      showFeatureLegend:
                          usePlanStudio &&
                          plan == currentPlan &&
                          !lockedDowngrade &&
                          !isReferenceCard,
                      isSelected: plan == selPlan && !lockedDowngrade,
                      isCurrent: plan == currentPlan,
                      isLockedDowngrade: lockedDowngrade,
                      referenceOnly: isReferenceCard,
                      nestedInAccordion: usePlanStudio ? false : nestedInAccordion,
                      dimUnselected: usePlanStudio
                          ? false
                          : hasUpgradeAbove &&
                              plan != currentPlan &&
                              plan != selPlan,
                      collapseFeatureDetails:
                          plan == currentPlan &&
                          currentPlan != SubscriptionPlan.FREE,
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
                      onTap: isReferenceCard
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
                  final currentTierPlans = upgradePlans
                      .where(
                        (p) => subscriptionPlanFromApi(p.nome) == currentPlan,
                      )
                      .toList();
                  final upperTierPlans = upgradePlans
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
                      _upgradeOffersExpanded ||
                      selPlan.level > currentPlan.level;
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
                          ink: ink,
                          mute: mute,
                          line: line,
                          primary: primary,
                          isDark: isDark,
                        ),
                      );
                    }

                    if (isCurrentPlanSelected &&
                        currentPlan == SubscriptionPlan.ENTERPRISE) {
                      final roiCard = PaywallEnterpriseProRoiCard(
                        ink: ink,
                        mute: mute,
                        isDark: isDark,
                        monthlyDelta: enterpriseProMonthlyDelta,
                        onExplorePro: () {
                          HapticFeedback.selectionClick();
                          _selectPlan(SubscriptionPlan.ENTERPRISE_PRO);
                        },
                      );
                      final existingBelow = studioBelowPlan;
                      studioBelowPlan = existingBelow == null
                          ? roiCard
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                existingBelow,
                                const SizedBox(height: 10),
                                roiCard,
                              ],
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
                              () => _upgradeOffersExpanded =
                                  plan.level > currentPlan.level,
                            );
                            _selectPlan(plan);
                          },
                          planContent: planCard(selBackend),
                          compareSection: studioCompare,
                          belowPlanSection: studioBelowPlan,
                          roiTag: enterpriseProRoiTag,
                          usageSnapshot: usage,
                          ink: ink,
                          mute: mute,
                          isDark: isDark,
                        ),
                      ),
                      if (lowerPlans.isNotEmpty || freePlano != null)
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
                        accent: nextTierPlan == null
                            ? primary
                            : PaywallCatalog.accentForPlan(nextTierPlan),
                        ink: ink,
                        mute: mute,
                        isDark: isDark,
                        title: nextTierPlan == null
                            ? 'Upgrade disponível'
                            : 'Upgrade disponível — ${PaywallCatalog.displayPlanName(nextTierPlan)}',
                        subtitle:
                            'Preços e benefícios na ${subscriptionChannelLabel()}',
                        children: [
                          for (final p in upperTierPlans) planCard(p),
                        ],
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
                else if (!usePlanStudio &&
                    hasUpgradeAbove &&
                    nextTierPlan != null)
                  PaywallSectionAnchor(
                    anchorKey: _paywallCompareKey,
                    child: PaywallSubscriberQuickCompare(
                    currentPlan: currentPlan,
                    targetPlan: nextTierPlan,
                    comparisonRows: vitrineComparison,
                    catalogFromApi: vitrine?.fromApi ?? false,
                    initiallyExpanded:
                        selPlan == nextTierPlan &&
                        selPlan.level > currentPlan.level,
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
                    text:
                        'No celular, assine pela App Store ou Google Play.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 16),
                PaywallSectionAnchor(
                  anchorKey: _paywallLegalKey,
                  child: !isAcquisition && isCurrentPlanSelected
                      ? PaywallSubscriberLegalStrip(
                          mute: mute,
                          primary: primary,
                          restoring: _restoringPurchases,
                          onRestore:
                              subscriptionUsesNativeStore ? _restorePurchases : null,
                        )
                      : PaywallUpgradeLegalCompact(
                          ink: ink,
                          mute: mute,
                          primary: primary,
                          showStoreBillingNote: subscriptionUsesNativeStore,
                          restoring: _restoringPurchases,
                          onRestore:
                              subscriptionUsesNativeStore ? _restorePurchases : null,
                        ),
                ),
              ],
          );
        },
      ),
    );
  }
}

class _EnterprisePreviewCard extends StatelessWidget {
  final EnterpriseUpgradePreview preview;
  final Color primary;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _EnterprisePreviewCard({
    required this.preview,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(preview.planoDestino);
    final destLabel = PaywallCatalog.displayPlanName(preview.planoDestino);
    return PaywallGlassCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      blur: false,
      elevationLevel: 4,
      child: Text(
        preview.cobrancaImediata
            ? 'Upgrade para $destLabel: cobrança proporcional de R\$ ${preview.valorProporcional.toStringAsFixed(2)} (${preview.diasRestantes} dias restantes no ciclo).'
            : 'Upgrade para $destLabel sem cobrança proporcional imediata neste ciclo.',
        style: TokensStrip.body(color: ink),
      ),
    );
  }
}

class _EnterpriseProUpgradePriceHint extends StatelessWidget {
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan targetPlan;
  final SubscriptionBillingPeriod billingPeriod;
  final Map<String, ProductDetails> productDetails;
  final Plano currentBackend;
  final Plano targetBackend;
  final Color primary;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _EnterpriseProUpgradePriceHint({
    required this.currentPlan,
    required this.targetPlan,
    required this.billingPeriod,
    required this.productDetails,
    required this.currentBackend,
    required this.targetBackend,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  String? _storeDeltaCopy() {
    final currentProduct = productDetails[
      SubscriptionProducts.productIdFor(currentPlan, billingPeriod)];
    final targetProduct = productDetails[
      SubscriptionProducts.productIdFor(targetPlan, billingPeriod)];
    if (currentProduct == null || targetProduct == null) return null;

    final currentRaw = currentProduct.rawPrice;
    final targetRaw = targetProduct.rawPrice;
    if (currentRaw <= 0 || targetRaw <= currentRaw) return null;

    final delta = targetRaw - currentRaw;
    final periodLabel =
        billingPeriod == SubscriptionBillingPeriod.yearly ? 'ano' : 'mês';
    return 'Diferença estimada na ${subscriptionChannelLabel()}: '
        '${targetProduct.currencySymbol}${delta.toStringAsFixed(2)}/$periodLabel '
        '(${currentProduct.price} → ${targetProduct.price}). '
        'A loja pode aplicar crédito proporcional do ciclo atual.';
  }

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(targetPlan);
    final targetLabel = PaywallCatalog.displayPlanName(targetPlan);
    final storeCopy = _storeDeltaCopy();
    final fallbackMonthly =
        targetBackend.precoMensal - currentBackend.precoMensal;
    final text = storeCopy ??
        (fallbackMonthly > 0
            ? 'Upgrade para $targetLabel: diferença de referência '
                'R\$ ${fallbackMonthly.toStringAsFixed(2)}/mês. '
                'Valor final e crédito proporcional confirmados na ${subscriptionChannelLabel()}.'
            : 'Upgrade para $targetLabel: valor final confirmado na ${subscriptionChannelLabel()} '
                'com possível crédito proporcional do ciclo atual.');

    return PaywallGlassCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      blur: false,
      elevationLevel: 4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TokensStrip.body(color: ink)),
          ),
        ],
      ),
    );
  }
}

enum _AssinaturaCtaMode { subscribe, manageStore, currentPlan, blocked, syncing }

class _AssinaturaStickyGlassBar extends StatelessWidget {
  final bool isDark;
  final Color line;
  final Widget child;

  const _AssinaturaStickyGlassBar({
    required this.isDark,
    required this.line,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: line.withValues(alpha: isDark ? 0.42 : 0.55),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(
            isDark ? TokensStrip.blurMedium : TokensStrip.blurLight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TokensStrip.glassFill(
                dark: isDark,
                opacity: isDark ? 0.86 : 0.91,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.42),
                  Colors.transparent,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AssinaturaStickyFooter extends StatelessWidget {
  final _AssinaturaCtaMode mode;
  final String label;
  final String? planSummary;
  final String footnote;
  final bool enabled;
  final bool loading;
  final bool trialHint;
  final bool showLegalConsent;
  final bool isUpgrade;
  final Color? tierAccent;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final VoidCallback onSubscribe;
  final VoidCallback onManage;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _AssinaturaStickyFooter({
    required this.mode,
    required this.label,
    this.planSummary,
    required this.footnote,
    required this.enabled,
    required this.loading,
    required this.trialHint,
    required this.showLegalConsent,
    this.isUpgrade = false,
    this.tierAccent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.onSubscribe,
    required this.onManage,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = mute.withValues(alpha: isDark ? 0.78 : 0.72);
    final isActionable =
        mode == _AssinaturaCtaMode.subscribe ||
        mode == _AssinaturaCtaMode.syncing ||
        mode == _AssinaturaCtaMode.manageStore;
    final onPressed =
        !enabled || loading || mode == _AssinaturaCtaMode.syncing
            ? null
            : mode == _AssinaturaCtaMode.subscribe
            ? onSubscribe
            : mode == _AssinaturaCtaMode.manageStore
            ? onManage
            : null;

    IconData? icon;
    if (mode == _AssinaturaCtaMode.manageStore) {
      icon = Icons.open_in_new_rounded;
    } else if (mode == _AssinaturaCtaMode.subscribe) {
      icon =
          trialHint
              ? Icons.card_giftcard_rounded
              : Icons.workspace_premium_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (planSummary != null) ...[
          Text(
            planSummary!,
            textAlign: TextAlign.center,
            style: TokensStrip.body(color: ink).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (trialHint) ...[
          Text(
            subscriptionUsesNativeStore
                ? 'Oferta introdutória aplicada pela loja ao concluir a assinatura.'
                : 'Cancele antes do fim do período gratuito para evitar cobrança.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
          const SizedBox(height: 8),
        ],
        if (secondaryLabel != null &&
            onSecondary != null &&
            mode == _AssinaturaCtaMode.manageStore) ...[
          FxLiquidSecondaryButton(
            label: secondaryLabel!,
            icon: Icons.workspace_premium_outlined,
            onPressed: onSecondary,
          ),
          const SizedBox(height: 8),
        ],
        if (isActionable)
          tierAccent != null
              ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TokensStrip.rButton),
                  border: Border.all(color: tierAccent!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: tierAccent!.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FxLiquidPrimaryButton(
                  label: label,
                  icon: icon,
                  loading: loading || mode == _AssinaturaCtaMode.syncing,
                  loadingLabel:
                      mode == _AssinaturaCtaMode.syncing
                          ? 'Sincronizando…'
                          : null,
                  onPressed: onPressed,
                ),
              )
              : FxLiquidPrimaryButton(
                label: label,
                icon: icon,
                loading: loading || mode == _AssinaturaCtaMode.syncing,
                loadingLabel:
                    mode == _AssinaturaCtaMode.syncing
                        ? 'Sincronizando…'
                        : null,
                onPressed: onPressed,
              )
        else
          FxLiquidPrimaryButton(
            label: label,
            onPressed: null,
          ),
        if (footnote.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            footnote,
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
        ],
        if (showLegalConsent) ...[
          const SizedBox(height: 10),
          _PaywallLegalConsentLine(
            ink: ink,
            mute: mute,
            primary: primary,
            isUpgrade: isUpgrade,
          ),
        ],
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatPrice(
  Plano plano,
  ProductDetails? productDetails,
  SubscriptionBillingPeriod period,
) {
  if (plano.precoMensal == 0) return 'Grátis';
  final suffix =
      period == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';
  if (productDetails != null) return '${productDetails.price}$suffix';
  if (period == SubscriptionBillingPeriod.yearly) {
    final annual = plano.annualPriceOrComputed();
    return 'R\$ ${annual.toStringAsFixed(2)}$suffix';
  }
  return 'R\$ ${plano.precoMensal.toStringAsFixed(2)}$suffix';
}
