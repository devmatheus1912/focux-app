import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/legal/focux_legal.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../../../features/subscription/services/iap_service.dart';
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
import '../services/subscription_biometric_gate.dart';
import '../services/subscription_device_guard.dart';
import '../assinatura_route_args.dart';
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
  final Set<String> _handledPurchases = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final ScrollController _paywallScrollController = ScrollController();

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
  bool _restoringPurchases = false;
  bool _paymentBlocked = false;
  bool _planReconcileAttempted = false;
  SubscriptionBillingPeriod _billingPeriod = SubscriptionBillingPeriod.yearly;
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
    FeedbackHelper.showInfo(context, 'Verificando compras anteriores...');

    try {
      final result = await ref
          .read(iapServiceProvider)
          .restoreAndVerifyPurchases(
            onVerified: (_, __) async {
              ref.invalidate(perfilProvider);
              ref.invalidate(planoFeaturesProvider);
            },
          );
      ref.invalidate(perfilProvider);
      ref.invalidate(planoFeaturesProvider);

      if (!mounted) return;

      if (!result.storeAvailable) {
        FeedbackHelper.showError(
          context,
          'A loja do dispositivo não está disponível.',
        );
        return;
      }

      if (result.hasVerifiedPurchases) {
        FeedbackHelper.showSuccess(context, 'Compras restauradas com sucesso.');
        return;
      }

      if (result.errors.isNotEmpty) {
        FeedbackHelper.showError(context, result.errors.first.message);
        return;
      }

      FeedbackHelper.showInfo(context, 'Nenhuma compra anterior encontrada.');
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(error, fallback: 'Erro ao restaurar compras.'),
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
          _finishPurchaseFlowWithError(
            friendlyError(error, fallback: 'Erro ao acompanhar a compra.'),
          );
        },
      );
    }
    _initializeStore();
    _loadTrialStatus();
    _checkDeviceSecurity();
    _paywallFreshnessSub = ref.listenManual(paywallHomeProvider, (_, next) {
      if (!next.hasValue || next.isLoading || next.hasError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _paywallFetchedAt = DateTime.now());
      });
    }, fireImmediately: true);
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
      'Downgrade e cancelamento só nas assinaturas do ${subscriptionChannelLabel()}.',
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
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
              assinaturaStoreFailureCopy(),
              reason: 'iap_store',
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
      ref.invalidate(paywallHomeProvider);

      if (!mounted) return;

      AnalyticsService.instance.track(
        ProductEvents.checkoutCompleted,
        props: {
          'plan_id': purchasedPlan.apiName,
          if (purchase.purchaseID != null)
            'transaction_id': purchase.purchaseID,
        },
      );

      if (!mounted) return;
      await context.push<void>(
        '/assinatura/success',
        extra: AssinaturaSuccessRouteArgs(
          plan: purchasedPlan,
          transactionId: purchase.purchaseID,
        ),
      );
      if (mounted) safePopOrGo(context, '/dashboard/personal');
    } catch (error) {
      _handledPurchases.remove(purchaseKey);
      _finishPurchaseFlowWithError(
        friendlyError(
          error,
          fallback: 'Não foi possível sincronizar a assinatura.',
        ),
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

    if (!kIsWeb && subscriptionUsesNativeStore) {
      final biometricOk = await SubscriptionBiometricGate.confirmSubscription(
        planName: plan.apiName,
      );
      if (!mounted || !biometricOk) return;

      final product =
          _productDetails[SubscriptionProducts.productIdFor(
            plan,
            _billingPeriod,
          )];
      final priceDisplay = _formatPrice(backendPlan, product, _billingPeriod);
      final billingPlan = subscriptionPlanFromApi(
        ref.read(perfilProvider).valueOrNull?.plano,
      );
      final trialNote =
          paywallShowsMaxPlanTrial(
                selected: plan,
                current: billingPlan,
                trialEligible: _trialStatus?.trialEligible,
              )
              ? '$kPaywallMaxPlanTrialDays dias grátis no Enterprise com cadastro de cartão. '
                  'A loja confirma o valor após o período.'
              : null;
      final confirmed = await context.push<bool>(
        '/assinatura/review',
        extra: AssinaturaReviewRouteArgs(
          plan: plan,
          billingPeriod: _billingPeriod,
          priceDisplay: priceDisplay,
          trialNote: trialNote,
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
      _finishPurchaseFlowWithError(
        friendlyError(error, fallback: 'Erro ao iniciar a compra na loja.'),
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
