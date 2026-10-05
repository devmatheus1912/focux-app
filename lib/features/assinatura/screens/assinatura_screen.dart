import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/legal/focux_legal.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/referral/data/referral_repository.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../../../features/subscription/services/iap_purchase_coordinator.dart';
import '../../../features/subscription/services/iap_purchase_event.dart';
import '../../../features/subscription/store_subscription_policy.dart';
import '../../../features/subscription/subscription_products.dart';

import '../data/assinatura_repository.dart';
import '../data/plano.dart';
import '../providers/assinatura_provider.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../planos/paywall/paywall_components.dart';
import '../../planos/paywall/paywall_price.dart';
import '../../planos/paywall/paywall_vitrine.dart';
import '../../subscription/plan_entitlements.dart';
import '../services/subscription_device_guard.dart';
import '../assinatura_route_args.dart';
import '../utils/assinatura_checkout_events.dart';
import '../utils/assinatura_review_display.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

part 'assinatura_screen_footer.part.dart';
part 'assinatura_screen_build.part.dart';
part 'assinatura_screen_build_body.part.dart';

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

/// Nota curta no sticky — nunca um card por cima da tabela.
String? _enterprisePreviewFootnote(
  EnterpriseUpgradePreview preview,
  SubscriptionPlan currentPlan,
  SubscriptionPlan selectedPlan,
) {
  if (!_enterprisePreviewIsInformative(preview, currentPlan, selectedPlan)) {
    return null;
  }
  if (preview.cobrancaImediata) {
    return 'Cobrança proporcional de '
        '${formatPaywallBrl(preview.valorProporcional)} neste ciclo.';
  }
  return 'Sem cobrança proporcional neste ciclo.';
}

bool _shouldLoadEnterprisePreview(
  SubscriptionPlan currentPlan,
  SubscriptionPlan selectedPlan,
) {
  if (selectedPlan.level <= currentPlan.level) return false;
  return selectedPlan == SubscriptionPlan.ENTERPRISE;
}

/// Plano pré-selecionado: atual por padrão; deep link só se for upgrade válido.
/// FREE sem deep link: fica em FREE (Home first) — upgrade é escolha, não default.
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
  return currentPlan.apiName;
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
  StreamSubscription<IapPurchaseEvent>? _purchaseEvents;
  final ScrollController _paywallScrollController = ScrollController();

  String? _selectedPlanName;
  bool _loadingCheckout = false;
  bool _syncingPurchase = false;
  String? _checkoutProductId;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _productDetails = const {};
  Map<String, ProductDetails> _trialOffers = const {};
  Map<String, ProductDetails> _referralOffers = const {};
  /// Desconto de indicado ainda não usado (só mensais).
  int? _referralPct;
  /// Segundo toque no iPhone vai para a compra normal (código já resgatado ou recusado).
  bool _appleReferralCodeOpened = false;
  bool? _storeTrialEligible;
  EnterpriseUpgradePreview? _enterprisePreview;
  bool _enterprisePreviewRequested = false;
  bool _initialSelectionApplied = false;

  // Trial
  TrialStatus? _trialStatus;
  bool _restoringPurchases = false;
  bool _paymentBlocked = false;
  bool _planReconcileAttempted = false;
  /// Anual por padrão; vira mensal quando a loja confirma o teste grátis (só existe no PRO mensal).
  SubscriptionBillingPeriod _billingPeriod = SubscriptionBillingPeriod.yearly;
  bool _billingPeriodTouched = false;
  DateTime? _paywallFetchedAt;
  ProviderSubscription<AsyncValue<PaywallHomeBundle>>? _paywallFreshnessSub;

  Future<void> _checkDeviceSecurity() async {
    if (kIsWeb) return;
    final compromised = await SubscriptionDeviceGuard.isCompromised();
    if (mounted && compromised) setState(() => _paymentBlocked = true);
  }

  Future<void> _restorePurchases() async {
    if (_restoringPurchases || !subscriptionUsesNativeStore) return;

    setState(() => _restoringPurchases = true);
    FeedbackHelper.showInfo(context, S.of(context).assinaturaVerificandoCompras);

    try {
      final result = await ref.read(iapPurchaseCoordinatorProvider).restore();

      if (!mounted) return;

      if (!result.storeAvailable) {
        FeedbackHelper.showError(
          context,
          S.of(context).assinaturaLojaDispositivoIndisponivel,
        );
        return;
      }

      if (result.hasVerifiedPurchases) {
        FeedbackHelper.showSuccess(context, S.of(context).assinaturaComprasRestauradas);
        return;
      }

      if (result.hasFailures) {
        FeedbackHelper.showError(
          context,
          S.of(context).assinaturaRestaurarFalhou,
        );
        return;
      }

      FeedbackHelper.showInfo(context, S.of(context).assinaturaNenhumaCompraAnterior);
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(error, fallback: S.of(context).assinaturaErroRestaurar),
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
      _purchaseEvents = ref
          .read(iapPurchaseCoordinatorProvider)
          .events
          .listen(_onPurchaseEvent);
    }
    _initializeStore();
    _loadTrialStatus();
    _loadReferralDiscount();
    _checkDeviceSecurity();
    _paywallFreshnessSub = ref.listenManual(paywallHomeProvider, (_, next) {
      if (!next.hasValue || next.isLoading || next.hasError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _paywallFetchedAt = DateTime.now());
      });
    }, fireImmediately: true);
    if (subscriptionPlanFromApi(widget.initialPlan) == SubscriptionPlan.ENTERPRISE) {
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
        FeedbackHelper.showError(
          context,
          'Não foi possível abrir as assinaturas do dispositivo.',
        );
      }
      return;
    }
    FeedbackHelper.showInfo(
      context,
      'Gerencie sua assinatura na área de cobrança da web.',
    );
  }

  Future<void> _reconcilePlanFromServer() async {
    await ref.read(assinaturaRepositoryProvider).clearVitrineCache();
    ref.invalidate(paywallHomeProvider);
    await ref
        .read(planoFeaturesProvider.notifier)
        .refresh(reconcileFirst: true);
    ref.invalidate(perfilProvider);
  }

  void _maybeReconcilePlanOnLoad({
    required SubscriptionPlan billingPlan,
    required PlanoFeatures? meFeatures,
  }) {
    if (_planReconcileAttempted || meFeatures == null) return;
    if (meFeatures.plano.level >= billingPlan.level) return;
    _planReconcileAttempted = true;
    unawaited(_reconcilePlanFromServer());
  }

  void _handleDowngradeTierTap() {
    HapticFeedback.lightImpact();
    FeedbackHelper.showInfo(
      context,
      'Downgrade e cancelamento só nas assinaturas ${subscriptionChannelWith(ChannelPreposition.de)}.',
    );
  }

  @override
  void dispose() {
    _purchaseEvents?.cancel();
    _paywallFreshnessSub?.close();
    _paywallScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrialStatus() async {
    try {
      final status =
          await PlanosRepository(ref.read(apiClientProvider)).getTrialStatus();
      if (mounted) {
        setState(() => _trialStatus = status);
      }
    } catch (_) {
      // Sem trial: CTA segue no preço cheio.
    }
  }

  Future<void> _loadReferralDiscount() async {
    try {
      final pct = await ReferralRepository(
        ref.read(apiClientProvider),
      ).descontoPendentePct();
      if (mounted && pct != null && pct > 0) {
        setState(() => _referralPct = pct);
      }
    } catch (_) {
      // Sem desconto: checkout no preço normal.
    }
  }

  /// Desconto de indicação aplicável a este produto (Android: só com a oferta da Play carregada).
  bool _referralApplies(String productId) =>
      _referralPct != null &&
      SubscriptionProducts.referralDiscountProductIds.contains(productId) &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          _referralOffers.containsKey(productId));

  /// iPhone: abre o resgate do código de oferta da Apple (20% no primeiro mês
  /// pago). false = sem código; segue a compra normal.
  Future<bool> _redeemAppleReferralCode(String productId) async {
    final l10n = S.of(context);
    setState(() => _loadingCheckout = true);
    try {
      final codigo = await ReferralRepository(
        ref.read(apiClientProvider),
      ).codigoApple(productId);
      if (!mounted) return true;
      final code = codigo.codigo;
      if (code == null) {
        FeedbackHelper.showInfo(context, l10n.assinaturaIndicacaoSemCodigo);
        return false;
      }
      setState(() {
        _checkoutProductId = productId;
        _appleReferralCodeOpened = true;
      });
      final url = codigo.urlResgate;
      if (url != null &&
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        return true;
      }
      await copySensitiveToClipboard(code);
      if (!mounted) return true;
      FeedbackHelper.showInfo(context, l10n.assinaturaIndicacaoCodigoCopiado);
      await InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
          .presentCodeRedemptionSheet();
      return true;
    } catch (_) {
      if (mounted) {
        FeedbackHelper.showInfo(context, l10n.assinaturaIndicacaoSemCodigo);
      }
      return false;
    } finally {
      if (mounted) setState(() => _loadingCheckout = false);
    }
  }

  /// Na loja, o grátis aparece só se a própria loja confirmar a elegibilidade.
  bool? get _paywallTrialEligible =>
      subscriptionUsesNativeStore
          ? (_storeTrialEligible ?? false)
          : _trialStatus?.trialEligible;

  Future<void> _initializeStore() async {
    if (kIsWeb) {
      if (mounted) setState(() => _storeAvailable = false);
      return;
    }

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!mounted) return;

      setState(() => _storeAvailable = available);

      if (!available) return;

      final response = await InAppPurchase.instance.queryProductDetails(
        SubscriptionProducts.allStoreProductIds,
      );
      if (!mounted) return;

      final trialProductId = SubscriptionProducts.productIdFor(
        kTrialPlan,
        SubscriptionBillingPeriod.monthly,
      );
      final trialOffers = SubscriptionProducts.freeTrialOffersById(
        response.productDetails,
      );
      final bool? trialEligible =
          defaultTargetPlatform == TargetPlatform.android
              ? trialOffers.containsKey(trialProductId)
              : await ref
                  .read(iapPurchaseCoordinatorProvider)
                  .introOfferEligible(trialProductId);
      if (!mounted) return;

      setState(() {
        _productDetails = SubscriptionProducts.displayById(
          response.productDetails,
        );
        _trialOffers = trialOffers;
        _referralOffers = SubscriptionProducts.referralOffersById(
          response.productDetails,
        );
        _storeTrialEligible = trialEligible;
        if (trialEligible == true && !_billingPeriodTouched) {
          _billingPeriod = SubscriptionBillingPeriod.monthly;
        }
      });
    } catch (_) {
      // Sem catálogo da loja: o checkout consulta o produto de novo.
    }
  }

  /// Produto com preço da loja; null se a loja não devolver o item.
  Future<ProductDetails?> _storeProduct(String productId) async {
    final cached = _productDetails[productId];
    if (cached != null) return cached;
    try {
      final response = await InAppPurchase.instance.queryProductDetails({
        productId,
      });
      if (!mounted || response.productDetails.isEmpty) return null;
      final display = SubscriptionProducts.displayById(response.productDetails);
      final product = display[productId];
      if (product == null) return null;
      setState(() {
        _productDetails = {..._productDetails, productId: product};
        _trialOffers = {
          ..._trialOffers,
          ...SubscriptionProducts.freeTrialOffersById(response.productDetails),
        };
        _referralOffers = {
          ..._referralOffers,
          ...SubscriptionProducts.referralOffersById(response.productDetails),
        };
      });
      return product;
    } catch (_) {
      return null;
    }
  }

  /// Só a compra iniciada nesta tela mexe na UI; renovação e restore passam
  /// pelo coordenador global em silêncio.
  void _onPurchaseEvent(IapPurchaseEvent event) {
    if (!mounted || _restoringPurchases) return;
    if (!assinaturaCheckoutOwnsEvent(
      event,
      checkoutProductId: _checkoutProductId,
    )) {
      return;
    }
    switch (event) {
      case IapPurchaseCanceled():
        setState(() {
          _loadingCheckout = false;
          _syncingPurchase = false;
          _checkoutProductId = null;
        });
      case IapPurchaseSuperseded():
        // A loja devolveu a transação antiga em vez de abrir a compra.
        setState(() {
          _loadingCheckout = false;
          _syncingPurchase = false;
          _checkoutProductId = null;
        });
        FeedbackHelper.showInfo(context, S.of(context).assinaturaJaExisteNaLoja);
      case IapPurchaseStoreError():
        _finishPurchaseFlowWithError(
          assinaturaStoreFailureCopy(),
          reason: 'iap_store',
        );
      case IapPurchaseUnsupported():
        _finishPurchaseFlowWithError(S.of(context).assinaturaProdutoNaoSuportado);
      case IapPurchaseVerifying(:final purchase):
        final plan = _planForProductId(purchase.productID);
        setState(() {
          _loadingCheckout = false;
          _syncingPurchase = true;
          if (plan != null) _selectedPlanName = plan.apiName;
        });
      case IapPurchaseVerified(:final purchase):
        unawaited(_openCheckoutSuccess(purchase));
      case IapPurchaseVerifyFailed(:final error):
        _finishPurchaseFlowWithError(
          assinaturaVerifyFailedMessage(
            S.of(context),
            error,
            isAndroid: defaultTargetPlatform == TargetPlatform.android,
          ),
        );
      case IapPurchasePending():
        _checkoutProductId = null;
        setState(() {
          _loadingCheckout = false;
          _syncingPurchase = false;
        });
        FeedbackHelper.showInfo(
          context,
          S.of(context).assinaturaCompraAguardandoAprovacao,
        );
      case IapPurchaseBatchProcessed() || IapPurchaseStreamFailed():
        break;
    }
  }

  Future<void> _openCheckoutSuccess(PurchaseDetails purchase) async {
    final purchasedPlan = _planForProductId(purchase.productID);
    try {
      if (purchasedPlan == null) return;
      AnalyticsService.instance.track(
        ProductEvents.checkoutCompleted,
        props: {
          'plan_id': purchasedPlan.apiName,
          if (purchase.purchaseID != null)
            'transaction_id': purchase.purchaseID,
        },
      );
      await context.push<void>(
        '/assinatura/success',
        extra: AssinaturaSuccessRouteArgs(
          plan: purchasedPlan,
          transactionId: purchase.purchaseID,
        ),
      );
      if (mounted) safePopOrGo(context, '/dashboard/personal');
    } finally {
      _checkoutProductId = null;
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

    final perfil = ref.read(perfilProvider).value;
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

    if (!kIsWeb && subscriptionUsesNativeStore && !_storeAvailable) {
      FeedbackHelper.showError(
        context,
        'Loja do dispositivo indisponível. Tente novamente em instantes.',
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

    ProductDetails? storeProduct;
    if (!kIsWeb && subscriptionUsesNativeStore) {
      final productId = SubscriptionProducts.productIdFor(plan, _billingPeriod);
      storeProduct = productId.isEmpty ? null : await _storeProduct(productId);
      if (!mounted) return;
      if (storeProduct == null) {
        _finishPurchaseFlowWithError(
          'Não conseguimos carregar o preço na loja. Tente de novo em instantes.',
        );
        return;
      }

      final priceDisplay = _formatPrice(
        backendPlan,
        storeProduct,
        _billingPeriod,
      );
      final billingPlan = subscriptionPlanFromApi(
        ref.read(perfilProvider).value?.plano,
      );
      final trialNote =
          paywallShowsTrial(
                selected: plan,
                current: billingPlan,
                trialEligible: _paywallTrialEligible,
                period: _billingPeriod,
              )
              ? S.of(context).assinaturaTrialNota(
                  kTrialDays,
                  PaywallCatalog.displayPlanName(plan),
                  subscriptionCancelWhere(),
                )
              : null;
      final referralNote = _referralApplies(productId)
          ? '${S.of(context).assinaturaIndicacaoSelo(_referralPct!)}.'
          : null;
      final reviewNote = [trialNote, referralNote].nonNulls.join(' ');
      final confirmed = await context.push<bool>(
        '/assinatura/review',
        extra: AssinaturaReviewRouteArgs(
          plan: plan,
          billingPeriod: _billingPeriod,
          priceDisplay: priceDisplay,
          trialNote: reviewNote.isEmpty ? null : reviewNote,
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
        _finishPurchaseFlowWithError(
          friendlyError(error, fallback: 'Erro ao gerar checkout web.'),
        );
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

    final product = storeProduct ?? await _storeProduct(productId);
    if (!mounted) return;
    if (product == null) {
      _finishPurchaseFlowWithError(
        S.of(context).assinaturaProdutoNaoConfigurado,
      );
      return;
    }

    final referralDiscount = _referralApplies(productId);
    if (referralDiscount &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !_appleReferralCodeOpened) {
      if (await _redeemAppleReferralCode(productId)) return;
      if (!mounted) return;
    }
    if (!referralDiscount &&
        _referralPct != null &&
        defaultTargetPlatform == TargetPlatform.android &&
        SubscriptionProducts.referralDiscountProductIds.contains(productId)) {
      FeedbackHelper.showInfo(context, S.of(context).assinaturaIndicacaoSemCodigo);
    }
    final referralOffer =
        referralDiscount && defaultTargetPlatform == TargetPlatform.android
            ? _referralOffers[productId]
            : null;
    final trialOffer =
        defaultTargetPlatform == TargetPlatform.android &&
                paywallShowsTrial(
                  selected: plan,
                  current: subscriptionPlanFromApi(
                    ref.read(perfilProvider).value?.plano,
                  ),
                  trialEligible: _paywallTrialEligible,
                  period: _billingPeriod,
                )
            ? _trialOffers[productId]
            : null;
    final productToBuy = referralOffer ?? trialOffer ?? product;
    setState(() {
      _loadingCheckout = true;
      _checkoutProductId = productToBuy.id;
    });

    try {
      final opened = await ref
          .read(iapPurchaseCoordinatorProvider)
          .buy(
            productToBuy,
            accountToken: ref.read(perfilProvider).value?.iapAccountToken,
          );
      if (opened) return;
      if (!mounted) return;
      _finishPurchaseFlowWithError(
        S.of(context).assinaturaLojaIndisponivel,
        reason: 'iap_listener',
      );
    } catch (error) {
      if (!mounted) return;
      _finishPurchaseFlowWithError(
        assinaturaBuyErrorMessage(S.of(context), error),
      );
    }
  }

  void _finishPurchaseFlowWithError(
    String message, {
    String reason = 'checkout',
  }) {
    AnalyticsService.instance.track(
      ProductEvents.checkoutFailed,
      props: {'reason': reason},
    );
    _checkoutProductId = null;
    if (!mounted) return;
    setState(() {
      _loadingCheckout = false;
      _syncingPurchase = false;
    });
    FeedbackHelper.showError(context, message);
  }

  @override
  Widget build(BuildContext context) => fxScreenA11yScope(
    label: 'Assinatura',
    child: buildAssinaturaScreen(context),
  );
}
