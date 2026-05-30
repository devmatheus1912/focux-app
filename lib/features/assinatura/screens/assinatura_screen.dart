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
import '../../../core/theme/shell_chrome.dart';
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

import '../data/assinatura_repository.dart';
import '../providers/assinatura_provider.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../planos/paywall/paywall_components.dart';
import '../../planos/paywall/paywall_vitrine.dart';
import '../../subscription/plan_entitlements.dart';
import '../services/subscription_biometric_gate.dart';
import '../services/subscription_device_guard.dart';
import 'assinatura_review_screen.dart';
import 'assinatura_success_screen.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';

part 'paywall_layout.dart';

/// Preview de upgrade só quando há dados úteis para quem ainda não é Enterprise.
bool _enterprisePreviewIsInformative(
  EnterpriseUpgradePreview preview,
  SubscriptionPlan currentPlan,
  SubscriptionPlan selectedPlan,
) {
  if (currentPlan == SubscriptionPlan.ENTERPRISE) return false;
  if (selectedPlan != SubscriptionPlan.ENTERPRISE) return false;
  if (preview.planoDestino != SubscriptionPlan.ENTERPRISE) return false;
  return preview.cobrancaImediata ||
      preview.diasRestantes > 0 ||
      preview.valorProporcional > 0 ||
      preview.diferencaDiaria > 0;
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
  return trialStatus?.trialUsed != true;
}

class AssinaturaScreen extends ConsumerStatefulWidget {
  final String? initialPlan;
  final String? source;
  final String? blockedFeature;

  const AssinaturaScreen({
    super.key,
    this.initialPlan,
    this.source,
    this.blockedFeature,
  });

  @override
  ConsumerState<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends ConsumerState<AssinaturaScreen> {
  final Set<String> _handledPurchases = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

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

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
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

    AnalyticsService.instance.track(
      ProductEvents.paywallPlanSelected,
      props: {'plan_id': plan.apiName},
    );

    setState(() {
      _selectedPlanName = plan.apiName;
      if (plan != SubscriptionPlan.ENTERPRISE) {
        _enterprisePreview = null;
        _enterprisePreviewRequested = false;
      }
    });

    if (plan == SubscriptionPlan.ENTERPRISE) await _loadEnterprisePreview();
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
                  (_trialStatus?.trialUsed == false)
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
    final featuresAsync = ref.watch(planoFeaturesProvider);

    final planos = planosAsync.valueOrNull;

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
        footnote = '';
      } else if (selectedPlan == SubscriptionPlan.FREE) {
        ctaMode = _AssinaturaCtaMode.blocked;
        ctaLabel = 'Plano gratuito';
        ctaEnabled = false;
        footnote = 'O plano gratuito não requer assinatura.';
      } else {
        ctaMode = _AssinaturaCtaMode.subscribe;
        ctaEnabled = !_loadingCheckout;
        final trialOffer =
            selectedPlan == SubscriptionPlan.ENTERPRISE &&
            (_trialStatus?.trialUsed == false);
        final isUpgrade = selectedPlan.level > currentPlan.level;
        ctaLabel = trialOffer
            ? 'Começar 7 dias grátis — Enterprise'
            : isUpgrade && selectedPlan == SubscriptionPlan.ENTERPRISE_PRO
            ? 'Fazer upgrade para Enterprise Pro'
            : isUpgrade && selectedPlan == SubscriptionPlan.ENTERPRISE
            ? 'Fazer upgrade para Enterprise'
            : selectedPlan == SubscriptionPlan.ENTERPRISE_PRO
            ? 'Continuar com Enterprise Pro'
            : selectedPlan == SubscriptionPlan.ENTERPRISE
            ? 'Continuar com Enterprise'
            : 'Continuar com Premium';
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
        (_trialStatus?.trialUsed == false);
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
          IconButton(
            icon: const Icon(Icons.exit_to_app_outlined),
            tooltip: 'Cancelar assinatura',
            onPressed: () => context.push('/cancel-save'),
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
                    footnote: footnote,
                    enabled: ctaEnabled,
                    loading: _loadingCheckout || _syncingPurchase,
                    trialHint: trialOffer,
                    showLegalConsent: ctaMode == _AssinaturaCtaMode.subscribe,
                    ink: ink,
                    mute: mute,
                    line: line,
                    primary: primary,
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
          final isCurrentPlanSelected = selPlan == currentPlan;

          if (selPlan == SubscriptionPlan.ENTERPRISE &&
              currentPlan != SubscriptionPlan.ENTERPRISE &&
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

          return ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s5,
                4,
                TokensStrip.s5,
                140,
              ),
              children: [
                PaywallHero(ink: ink, mute: mute, primary: primary, isDark: isDark),
                if (usage != null)
                  PaywallContextBanner(
                    usage: usage,
                    blockedFeatureLabel: widget.blockedFeature,
                    ink: ink,
                    mute: mute,
                    onCta: () {
                      final target = PlanEntitlements.softGateTargetPlan(usage);
                      if (target != null) _selectPlan(target);
                    },
                  ),
                PaywallSocialProofStrip(
                  line: line,
                  ink: ink,
                  mute: mute,
                  socialProof:
                      (ref.watch(paywallVitrineProvider).valueOrNull ??
                              PaywallVitrineSnapshot.fromCatalog())
                          .socialProof,
                ),
                if (!kIsWeb && subscriptionUsesNativeStore) ...[
                  _PaywallBillingSegment(
                    period: _billingPeriod,
                    ink: ink,
                    mute: mute,
                    line: line,
                    primary: primary,
                    isDark: isDark,
                    annualSavingsLabel: SubscriptionProducts.annualSavingsCompactLabel(
                      paid
                          .map((p) => p.precoMensal)
                          .fold<double>(0, (a, b) => a > b ? a : b),
                    ),
                    onChanged: (period) {
                      HapticFeedback.selectionClick();
                      AnalyticsService.instance.track(
                        ProductEvents.billingToggleChanged,
                        props: {'to': period.name},
                      );
                      setState(() => _billingPeriod = period);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                PaywallSectionHeader(
                  title: 'Planos',
                  note: 'Mensal e anual lado a lado',
                  ink: ink,
                  mute: mute,
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

                  Widget planCard(Plano plano) {
                    final plan = subscriptionPlanFromApi(plano.nome);
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
                    return PaywallRichPlanCard(
                      plano: plano,
                      plan: plan,
                      isSelected: plan == selPlan,
                      isCurrent: plan == currentPlan,
                      monthlyPrice: monthlyPrice,
                      annualPrice: annualPrice,
                      ink: ink,
                      mute: mute,
                      line: line,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _selectPlan(plan);
                      },
                    );
                  }

                  return [
                    ...visiblePlans.map(planCard),
                    if (currentPlan != SubscriptionPlan.FREE && freePlano != null)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Ver plano gratuito',
                            style: TokensStrip.body(color: ink),
                          ),
                          subtitle: Text(
                            'Referência do tier FREE',
                            style: TokensStrip.bodyMuted(color: mute),
                          ),
                          children: [planCard(freePlano)],
                        ),
                      ),
                  ];
                }(),
                PaywallRoiStrip(line: line, ink: ink, mute: mute),
                if (currentPlan == SubscriptionPlan.PREMIUM &&
                    selPlan == SubscriptionPlan.ENTERPRISE &&
                    !isCurrentPlanSelected) ...[
                  const SizedBox(height: 16),
                  _PaywallUpgradeNudge(primary: primary, ink: ink, isDark: isDark),
                ],
                PaywallRoiCalculator(
                  paidPlans: paid,
                  ink: ink,
                  mute: mute,
                  line: line,
                  onSuggestPlan: _selectPlan,
                ),
                PaywallSectionHeader(
                  title: 'Features',
                  note: '10 maiores diferenciais',
                  ink: ink,
                  mute: mute,
                ),
                PaywallFeaturesGrid(
                  ink: ink,
                  mute: mute,
                  line: line,
                  isDark: isDark,
                ),
                PaywallComparisonTable(
                  ink: ink,
                  mute: mute,
                  line: line,
                  isDark: isDark,
                ),
                PaywallSectionHeader(
                  title: 'ROI',
                  note: 'Retorno por plano',
                  ink: ink,
                  mute: mute,
                ),
                PaywallRoiRowsList(
                  ink: ink,
                  mute: mute,
                  line: line,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _PaywallFeaturePanel(
                  plano: isCurrentPlanSelected
                      ? sortedPlans.firstWhere(
                          (p) => subscriptionPlanFromApi(p.nome) == currentPlan,
                          orElse: () => selBackend,
                        )
                      : selBackend,
                  plan: isCurrentPlanSelected ? currentPlan : selPlan,
                  currentPlan: currentPlan,
                  ink: ink,
                  mute: mute,
                  line: line,
                  primary: primary,
                  isDark: isDark,
                ),
                PaywallSectionHeader(
                  title: 'Gatilhos',
                  note: 'Toque para abrir',
                  ink: ink,
                  mute: mute,
                ),
                PaywallGatilhosList(
                  ink: ink,
                  mute: mute,
                  line: line,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                if (_shouldShowEnterpriseTrialCard(
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
                            : '7 dias grátis neste plano Enterprise.',
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
                  const SizedBox(height: 12),
                  _EnterprisePreviewCard(
                    preview: _enterprisePreview!,
                    primary: primary,
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                if (!_storeAvailable && !kIsWeb) ...[
                  const SizedBox(height: 12),
                  _PaywallInlineNote(
                    icon: Icons.store_outlined,
                    text: 'Loja do dispositivo indisponível nesta sessão.',
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
                PaywallTrustFooter(mute: mute, primary: primary),
                const SizedBox(height: 12),
                _PaywallLegalFooter(
                  ink: ink,
                  mute: mute,
                  showStoreBillingNote: subscriptionUsesNativeStore,
                  restoring: _restoringPurchases,
                  onRestore:
                      subscriptionUsesNativeStore ? _restorePurchases : null,
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
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: chrome.panel(radius: TokensStrip.rCard, elevationLevel: 1),
      child: Text(
        preview.cobrancaImediata
            ? 'Upgrade: cobrança proporcional de R\$ ${preview.valorProporcional.toStringAsFixed(2)} (${preview.diasRestantes} dias restantes no ciclo).'
            : 'Upgrade sem cobrança proporcional imediata neste ciclo.',
        style: TokensStrip.body(color: ink),
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
  final String footnote;
  final bool enabled;
  final bool loading;
  final bool trialHint;
  final bool showLegalConsent;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final VoidCallback onSubscribe;
  final VoidCallback onManage;

  const _AssinaturaStickyFooter({
    required this.mode,
    required this.label,
    required this.footnote,
    required this.enabled,
    required this.loading,
    required this.trialHint,
    required this.showLegalConsent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.onSubscribe,
    required this.onManage,
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
        if (isActionable)
          FxLiquidPrimaryButton(
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
          _PaywallLegalConsentLine(mute: mute, primary: primary),
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
