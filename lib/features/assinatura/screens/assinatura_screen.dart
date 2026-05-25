import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
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
import '../providers/assinatura_provider.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';

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

  const AssinaturaScreen({super.key, this.initialPlan});

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

  // Trial
  TrialStatus? _trialStatus;
  bool _loadingTrial = false;
  bool _restoringPurchases = false;
  SubscriptionBillingPeriod _billingPeriod = SubscriptionBillingPeriod.yearly;

  Color _planAccent(SubscriptionPlan plan, Color primary, bool isDark) {
    return switch (plan) {
      SubscriptionPlan.FREE =>
        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
      SubscriptionPlan.PREMIUM => primary,
      SubscriptionPlan.ENTERPRISE => const Color(0xFFC49A2A),
    };
  }

  String _planTag(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.PREMIUM => 'MAIS ESCOLHIDO',
      SubscriptionPlan.ENTERPRISE => 'MÁXIMO PODER',
      _ => '',
    };
  }

  String _planSubtitle(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.PREMIUM =>
        'IA, financeiro e identidade visual para escalar com previsibilidade.',
      SubscriptionPlan.ENTERPRISE =>
        'Operação ilimitada, white-label e automações para times que crescem rápido.',
      _ => 'Recursos essenciais para começar.',
    };
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
    _selectedPlanName = widget.initialPlan?.trim().toUpperCase();
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

      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            purchasedPlan == SubscriptionPlan.ENTERPRISE
                ? 'Assinatura Enterprise sincronizada com sucesso.'
                : 'Assinatura Premium iniciada com sucesso.',
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

  Future<void> _startCheckout(SubscriptionPlan plan, int planId) async {
    if (_loadingCheckout || _syncingPurchase) return;

    if (kIsWeb) {
      setState(() => _loadingCheckout = true);
      try {
        final checkoutUrl = await AssinaturaRepository(
          ref.read(apiClientProvider),
        ).criarPreferencia(planId);
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

    _selectedPlanName ??=
        widget.initialPlan?.trim().toUpperCase() ?? currentPlan.apiName;

    final heroPrimary = BrandPalette.softened(primary, amount: 0.10);
    final heroSecondary = BrandPalette.deep(primary);
    final planos = planosAsync.valueOrNull;

    SubscriptionPlan selectedPlan = currentPlan;
    Plano? selectedBackendPlan;
    var isCurrentPlan = false;
    var isDowngrade = false;
    var ctaEnabled = false;
    var ctaLabel = 'Assinar';
    var ctaMode = _AssinaturaCtaMode.subscribe;
    String footnote = '';

    if (planos != null && planos.isNotEmpty) {
      selectedPlan = subscriptionPlanFromApi(_selectedPlanName);
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
                ? 'Gerenciar assinatura'
                : 'Plano atual';
        ctaEnabled = subscriptionUsesNativeStore && !_loadingCheckout;
        footnote =
            subscriptionUsesNativeStore
                ? 'Renovação, cancelamento e troca de período (mensal/anual) são feitos na ${subscriptionChannelLabel()}.'
                : 'Este plano já está ativo na sua conta.';
      } else if (isDowngrade) {
        ctaMode =
            subscriptionUsesNativeStore
                ? _AssinaturaCtaMode.manageStore
                : _AssinaturaCtaMode.blocked;
        ctaLabel =
            subscriptionUsesNativeStore
                ? 'Gerenciar na loja'
                : 'Plano superior necessário';
        ctaEnabled = subscriptionUsesNativeStore;
        footnote =
            subscriptionUsesNativeStore
                ? 'Para reduzir o plano ou cancelar, use as configurações de assinatura do seu dispositivo.'
                : 'Selecione um plano superior ao atual para continuar.';
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
        ctaLabel =
            trialOffer
                ? 'Começar 7 dias grátis'
                : selectedPlan == SubscriptionPlan.ENTERPRISE
                ? 'Assinar Enterprise'
                : 'Assinar Premium';
        footnote =
            subscriptionUsesNativeStore
                ? (_billingPeriod == SubscriptionBillingPeriod.yearly
                    ? 'Plano anual com renovação automática pela loja. Cancele quando quiser.'
                    : 'Renovação automática mensal pela loja. Cancele quando quiser.')
                : 'Checkout seguro via Mercado Pago.';
      }
    }

    final trialOffer =
        selectedPlan == SubscriptionPlan.ENTERPRISE &&
        !isCurrentPlan &&
        (_trialStatus?.trialUsed == false);
    final brandDeep = BrandPalette.deep(primary);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Assinatura',
        subtitle: subscriptionUsesNativeStore ? 'LOJA' : 'CHECKOUT',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      bottomNavigationBar:
          selectedBackendPlan == null
              ? null
              : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _AssinaturaStickyFooter(
                  mode: ctaMode,
                  label: ctaLabel,
                  footnote: footnote,
                  enabled: ctaEnabled,
                  loading: _loadingCheckout || _syncingPurchase,
                  trialHint: trialOffer,
                  ink: ink,
                  mute: mute,
                  line: line,
                  primary: primary,
                  onSubscribe:
                      () => _startCheckout(
                        selectedPlan,
                        selectedBackendPlan!.id,
                      ),
                  onManage: _openSubscriptionManagement,
                ),
              ),
      body: planosAsync.when(
        loading: () => const FxLoading(),
        error: (error, _) => Center(child: Text('Erro: $error')),
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

          var selPlan = subscriptionPlanFromApi(_selectedPlanName);
          if (selPlan == SubscriptionPlan.FREE) {
            selPlan = subscriptionPlanFromApi(paid.last.nome);
          }

          final selBackend = sortedPlans.firstWhere(
            (plan) => subscriptionPlanFromApi(plan.nome) == selPlan,
            orElse: () => paid.last,
          );
          final selProductId = SubscriptionProducts.productIdFor(
            selPlan,
            _billingPeriod,
          );
          final selProduct = _productDetails[selProductId];
          final monthlyProduct =
              _productDetails[SubscriptionProducts.productIdFor(
                selPlan,
                SubscriptionBillingPeriod.monthly,
              )];
          final accent = _planAccent(selPlan, primary, isDark);
          final selDowngrade = selPlan.level < currentPlan.level;

          if (selPlan == SubscriptionPlan.ENTERPRISE &&
              currentPlan != SubscriptionPlan.ENTERPRISE &&
              !_enterprisePreviewRequested) {
            _enterprisePreviewRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadEnterprisePreview();
            });
          }

          return FxPremiumEntrance(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s5,
                6,
                TokensStrip.s5,
                140,
              ),
              children: [
                _AssinaturaHero(
                  isDark: isDark,
                  heroPrimary: heroPrimary,
                  heroSecondary: heroSecondary,
                  ink: ink,
                  mute: mute,
                  currentPlan: currentPlan,
                  billingPeriod: _billingPeriod,
                ),
                if (currentPlan != SubscriptionPlan.FREE) ...[
                  const SizedBox(height: 12),
                  _ActivePlanStatusChip(
                    plan: currentPlan,
                    billingPeriod: _billingPeriod,
                    primary: primary,
                    ink: ink,
                    mute: mute,
                    line: line,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 18),
                if (!kIsWeb && subscriptionUsesNativeStore) ...[
                  _BillingPeriodToggle(
                    period: _billingPeriod,
                    primary: primary,
                    isDark: isDark,
                    ink: ink,
                    mute: mute,
                    line: line,
                    onChanged: (period) {
                      HapticFeedback.selectionClick();
                      setState(() => _billingPeriod = period);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                if (paid.length > 1) ...[
                  _PlanSegmentBar(
                    plans: paid,
                    selected: selPlan,
                    currentPlan: currentPlan,
                    primary: primary,
                    isDark: isDark,
                    ink: ink,
                    mute: mute,
                    line: line,
                    onSelect: (plan) {
                      HapticFeedback.selectionClick();
                      _selectPlan(plan);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                FxStaggerItem(
                  index: 0,
                  child: _PremiumPlanShowcase(
                    plano: selBackend,
                    plan: selPlan,
                    currentPlan: currentPlan,
                    accent: accent,
                    brandDeep: brandDeep,
                    tag: _planTag(selPlan),
                    subtitle: _planSubtitle(selPlan),
                    priceLabel: _formatPrice(
                      selBackend,
                      selProduct,
                      _billingPeriod,
                    ),
                    billingPeriod: _billingPeriod,
                    monthlyPriceLabel: _formatPrice(
                      selBackend,
                      monthlyProduct,
                      SubscriptionBillingPeriod.monthly,
                    ),
                    trialStatus: _trialStatus,
                    isDark: isDark,
                    ink: ink,
                    mute: mute,
                  ),
                ),
                const SizedBox(height: 14),
                const FxStaggerItem(
                  index: 1,
                  child: _TrustStrip(),
                ),
                if (_shouldShowEnterpriseTrialCard(
                  selPlan,
                  currentPlan,
                  _trialStatus,
                )) ...[
                  const SizedBox(height: 12),
                  _TrialInfoCard(
                    trialStatus: _trialStatus,
                    loading: _loadingTrial,
                    isDark: isDark,
                    ink: ink,
                    mute: mute,
                    line: line,
                  ),
                ],
                if (isCurrentPlan && currentPlan != SubscriptionPlan.FREE) ...[
                  const SizedBox(height: 12),
                  _ManageSubscriptionCard(
                    primary: primary,
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                    onManage: _openSubscriptionManagement,
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
                if (selDowngrade) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    icon: Icons.info_outline,
                    text:
                        subscriptionUsesNativeStore
                            ? 'Para mudar para um plano menor ou cancelar, use as assinaturas do seu dispositivo.'
                            : 'Downgrade não está disponível aqui. Entre em contato com o suporte.',
                    color: EagleTokens.warn,
                    softColor: EagleTokens.warnSoft,
                    isDark: isDark,
                  ),
                ],
                if (!_storeAvailable && !kIsWeb) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    icon: Icons.store_outlined,
                    text:
                        'A loja do dispositivo não está disponível nesta sessão.',
                    color: mute,
                    softColor:
                        isDark
                            ? EagleTokens.darkCardHi
                            : TokensStrip.borderDefault,
                    isDark: isDark,
                  ),
                ],
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    icon: Icons.smartphone_outlined,
                    text:
                        'Na web, use o checkout seguro. No celular, assine pela App Store ou Google Play.',
                    color: mute,
                    softColor:
                        isDark
                            ? EagleTokens.darkCardHi
                            : TokensStrip.borderDefault,
                    isDark: isDark,
                  ),
                ],
                if (subscriptionUsesNativeStore) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    button: true,
                    label: 'Restaurar compras anteriores',
                    child: TextButton.icon(
                      onPressed: _restoringPurchases ? null : _restorePurchases,
                      icon:
                          _restoringPurchases
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.restore_rounded, size: 18),
                      label: Text(
                        _restoringPurchases
                            ? 'Restaurando…'
                            : 'Restaurar compras',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Premium layout (referência: paywalls ChatGPT / Claude) ─────────────────

class _BillingPeriodToggle extends StatelessWidget {
  final SubscriptionBillingPeriod period;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  const _BillingPeriodToggle({
    required this.period,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(SubscriptionBillingPeriod value, String label, {String? badge}) {
      final selected = period == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
            child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    selected
                        ? primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: selected ? null : Border.all(color: line),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: selected ? Colors.white : ink,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : EagleTokens.good,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(SubscriptionBillingPeriod.yearly, 'Anual', badge: '−20%'),
        const SizedBox(width: 8),
        chip(SubscriptionBillingPeriod.monthly, 'Mensal'),
      ],
    );
  }
}

class _AssinaturaHero extends StatelessWidget {
  final bool isDark;
  final Color heroPrimary;
  final Color heroSecondary;
  final Color ink;
  final Color mute;
  final SubscriptionPlan currentPlan;
  final SubscriptionBillingPeriod billingPeriod;

  const _AssinaturaHero({
    required this.isDark,
    required this.heroPrimary,
    required this.heroSecondary,
    required this.ink,
    required this.mute,
    required this.currentPlan,
    required this.billingPeriod,
  });

  String _headline() => switch (currentPlan) {
    SubscriptionPlan.ENTERPRISE =>
      'Sua operação no\nnível máximo',
    SubscriptionPlan.PREMIUM => 'Escale com IA,\nfinanceiro e CRM',
    _ => 'Desbloqueie o Focux\nno nível certo para você',
  };

  String _subtitle() {
    final period =
        billingPeriod == SubscriptionBillingPeriod.yearly ? 'anual' : 'mensal';
    return switch (currentPlan) {
      SubscriptionPlan.ENTERPRISE =>
        'Plano ${currentPlan.apiName} ativo. Compare períodos ($period) ou gerencie renovação na ${subscriptionChannelLabel()}.',
      SubscriptionPlan.PREMIUM =>
        'Plano ${currentPlan.apiName} ativo. Veja o Enterprise para alunos ilimitados e white-label.',
      _ =>
        'Treinos, IA Copiloto e financeiro em um fluxo seguro pela ${subscriptionChannelLabel()}.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [heroPrimary, heroSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: heroSecondary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FOCUX PREMIUM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: heroSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _headline(),
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.12,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _subtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSegmentBar extends StatelessWidget {
  final List<Plano> plans;
  final SubscriptionPlan selected;
  final SubscriptionPlan currentPlan;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final ValueChanged<SubscriptionPlan> onSelect;

  const _PlanSegmentBar({
    required this.plans,
    required this.selected,
    required this.currentPlan,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onSelect,
  });

  Color _accent(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => primary,
    SubscriptionPlan.ENTERPRISE => const Color(0xFFC49A2A),
    _ => mute,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          plans.map((plano) {
            final plan = subscriptionPlanFromApi(plano.nome);
            final isSelected = plan == selected;
            final accent = _accent(plan);
            final isCurrent = plan == currentPlan;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Plano ${plan.apiName}',
                child: GestureDetector(
                  onTap: () => onSelect(plan),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? accent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? null : Border.all(color: line),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          plan.apiName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isSelected ? Colors.white : ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plano.precoMensal == 0
                              ? 'Grátis'
                              : 'R\$ ${plano.precoMensal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isSelected
                                    ? Colors.white.withValues(alpha: 0.78)
                                    : mute,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ATUAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color:
                                  isSelected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _PremiumPlanShowcase extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final SubscriptionPlan currentPlan;
  final Color accent;
  final Color brandDeep;
  final String tag;
  final String subtitle;
  final String priceLabel;
  final SubscriptionBillingPeriod billingPeriod;
  final String? monthlyPriceLabel;
  final TrialStatus? trialStatus;
  final bool isDark;
  final Color ink;
  final Color mute;

  const _PremiumPlanShowcase({
    required this.plano,
    required this.plan,
    required this.currentPlan,
    required this.accent,
    required this.brandDeep,
    required this.tag,
    required this.subtitle,
    required this.priceLabel,
    required this.billingPeriod,
    this.monthlyPriceLabel,
    required this.trialStatus,
    required this.isDark,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = plan == currentPlan;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final showTrial =
        plan == SubscriptionPlan.ENTERPRISE &&
        (trialStatus == null || !trialStatus!.trialUsed);
    final hasGradient = plan != SubscriptionPlan.FREE;

    return FxGlowSurface(
      color: accent,
      enabled: !isCurrent,
      child: Container(
        decoration: fxListCardDecoration(
          context,
          accent: accent,
          radius: 22,
        ).copyWith(
          border: Border.all(
            color: isCurrent ? accent : line,
            width: isCurrent ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient:
                    hasGradient
                        ? LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.95),
                            plan == SubscriptionPlan.ENTERPRISE
                                ? const Color(0xFF2A1A00)
                                : brandDeep,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
              ),
              child: Stack(
                children: [
                  if (hasGradient)
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.auto_awesome, size: 120, color: Colors.white),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        'Plano ${plan.apiName}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: hasGradient ? Colors.white : ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color:
                              hasGradient
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : mute,
                        ),
                      ),
                      if (plano.precoMensal > 0) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              priceLabel
                                  .replaceAll('/mês', '')
                                  .replaceAll('/ano', ''),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: hasGradient ? Colors.white : accent,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              billingPeriod == SubscriptionBillingPeriod.yearly
                                  ? '/ano'
                                  : '/mês',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    hasGradient
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : mute,
                              ),
                            ),
                          ],
                        ),
                        if (billingPeriod == SubscriptionBillingPeriod.yearly) ...[
                          const SizedBox(height: 8),
                          Text(
                            SubscriptionProducts.savingsLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  hasGradient
                                      ? const Color(0xFFFFE08A)
                                      : EagleTokens.good,
                            ),
                          ),
                          if (monthlyPriceLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'vs $monthlyPriceLabel no mensal',
                              style: TextStyle(
                                fontSize: 11.5,
                                color:
                                    hasGradient
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : mute,
                              ),
                            ),
                          ],
                        ],
                      ],
                      if (showTrial) ...[
                        const SizedBox(height: 10),
                        Text(
                          subscriptionUsesNativeStore
                              ? 'Período de teste via ${subscriptionChannelLabel()}'
                              : '7 dias grátis incluídos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                hasGradient
                                    ? const Color(0xFFFFE08A)
                                    : EagleTokens.good,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  _ShowcaseFeatureRow(
                    label:
                        plano.limiteAlunos == null
                            ? 'Alunos ilimitados'
                            : 'Até ${plano.limiteAlunos} alunos',
                    active: true,
                    accent: accent,
                    mute: mute,
                  ),
                  _ShowcaseFeatureRow(
                    label: 'IA Copiloto avançada',
                    active: plan != SubscriptionPlan.FREE,
                    accent: accent,
                    mute: mute,
                  ),
                  _ShowcaseFeatureRow(
                    label: 'Financeiro e CRM',
                    active: plano.temFinanceiro,
                    accent: accent,
                    mute: mute,
                  ),
                  _ShowcaseFeatureRow(
                    label: 'White-label e domínio',
                    active: plano.temWhiteLabel,
                    accent: accent,
                    mute: mute,
                  ),
                  _ShowcaseFeatureRow(
                    label: 'Agenda e relatórios',
                    active: plano.temAgenda && plano.temRelatorios,
                    accent: accent,
                    mute: mute,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseFeatureRow extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final Color mute;

  const _ShowcaseFeatureRow({
    required this.label,
    required this.active,
    required this.accent,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  active
                      ? accent.withValues(alpha: 0.12)
                      : mute.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              active ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: active ? accent : mute,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? null : mute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    final storeIcon =
        subscriptionUsesNativeStore
            ? Icons.storefront_outlined
            : Icons.verified_user_outlined;
    final storeLabel =
        subscriptionUsesNativeStore ? 'Loja oficial' : 'Checkout web';

    final items = <MapEntry<IconData, String>>[
      MapEntry(Icons.lock_outline, 'Pagamento seguro'),
      MapEntry(Icons.autorenew, 'Cancele quando quiser'),
      MapEntry(storeIcon, storeLabel),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children:
          items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ink.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.key, size: 14, color: ink.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ink.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Estimativa de upgrade',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ink,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview.cobrancaImediata
                ? 'Cobrança proporcional: R\$ ${preview.valorProporcional.toStringAsFixed(2)}.'
                : 'Sem cobrança proporcional imediata neste upgrade.',
            style: TextStyle(color: ink, height: 1.45, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${preview.diasRestantes} dias restantes · diferença diária R\$ ${preview.diferencaDiaria.toStringAsFixed(2)}',
            style: TextStyle(color: mute, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Trial Info Card ─────────────────────────────────────────────────────────

class _TrialInfoCard extends StatelessWidget {
  final TrialStatus? trialStatus;
  final bool loading;
  final bool isDark;
  final Color ink, mute, line;

  const _TrialInfoCard({
    required this.trialStatus,
    required this.loading,
    required this.isDark,
    required this.ink,
    required this.mute,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context),
        child: const FxLoading(),
      );
    }

    final trialUsed = trialStatus?.trialUsed ?? false;
    final trialAtivo = trialStatus?.trialAtivo ?? false;
    final diasRestantes = trialStatus?.diasRestantes ?? 0;
    final trialEndsAt = trialStatus?.trialEndsAt;

    // Cores
    final accentColor =
        trialUsed
            ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
            : (isDark ? const Color(0xFF6FE296) : EagleTokens.good);
    final softColor =
        trialUsed
            ? (isDark ? const Color(0x22FF8B8B) : EagleTokens.badSoft)
            : (isDark ? const Color(0x226FE296) : EagleTokens.goodSoft);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trialUsed ? Icons.block_outlined : Icons.card_giftcard_outlined,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                trialAtivo
                    ? 'Período gratuito ativo'
                    : trialUsed
                    ? 'Período gratuito encerrado'
                    : 'Período gratuito disponível',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!trialUsed) ...[
            _TrialRow(
              icon: Icons.calendar_today_outlined,
              text:
                  subscriptionUsesNativeStore
                      ? 'Oferta introdutória (ex.: 7 dias) configurada na ${subscriptionChannelLabel()}.'
                      : '7 dias grátis incluídos neste plano.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon:
                  subscriptionUsesNativeStore
                      ? Icons.storefront_outlined
                      : Icons.credit_card_outlined,
              text:
                  subscriptionUsesNativeStore
                      ? 'O período de teste é ativado ao concluir a assinatura na loja do dispositivo.'
                      : 'É obrigatório cadastrar um cartão de crédito para ativar o período gratuito.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon: Icons.lock_outline,
              text:
                  subscriptionUsesNativeStore
                      ? 'Cancele nas configurações da loja antes do fim do período introdutório, se não quiser continuar.'
                      : 'Não haverá cobrança até o encerramento dos 7 dias. Cancele antes sem custo.',
              accentColor: accentColor,
            ),
          ] else if (trialAtivo) ...[
            _TrialRow(
              icon: Icons.timer_outlined,
              text:
                  'Período gratuito ativo — $diasRestantes dias restantes${trialEndsAt != null ? ' (encerra em ${_formatDate(trialEndsAt)})' : ''}.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon: Icons.credit_card_outlined,
              text:
                  'Sua cobrança começará automaticamente ao fim do trial. Cancele antes se não quiser continuar.',
              accentColor: accentColor,
            ),
          ] else ...[
            _TrialRow(
              icon: Icons.info_outline,
              text:
                  'Você já utilizou o período gratuito. A cobrança começa imediatamente ao assinar.',
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }
}

class _TrialRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accentColor;

  const _TrialRow({
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: accentColor, fontSize: 12.5, height: 1.45),
          ),
        ),
      ],
    );
  }
}

enum _AssinaturaCtaMode { subscribe, manageStore, currentPlan, blocked, syncing }

class _AssinaturaStickyFooter extends StatelessWidget {
  final _AssinaturaCtaMode mode;
  final String label;
  final String footnote;
  final bool enabled;
  final bool loading;
  final bool trialHint;
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
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.onSubscribe,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final usePrimary =
        mode == _AssinaturaCtaMode.subscribe ||
        mode == _AssinaturaCtaMode.syncing;
    final useManage =
        mode == _AssinaturaCtaMode.manageStore ||
        (mode == _AssinaturaCtaMode.blocked && subscriptionUsesNativeStore);

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
            style: TextStyle(
              color: mute,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          button: true,
          enabled: enabled && !loading,
          label: label,
          child:
              usePrimary
                  ? FxLiquidPrimaryButton(
                    label: label,
                    icon:
                        mode == _AssinaturaCtaMode.syncing
                            ? Icons.sync_rounded
                            : trialHint
                            ? Icons.card_giftcard_rounded
                            : Icons.workspace_premium_rounded,
                    loading: loading || mode == _AssinaturaCtaMode.syncing,
                    onPressed:
                        mode == _AssinaturaCtaMode.syncing
                            ? null
                            : (enabled ? onSubscribe : null),
                  )
                  : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: enabled && !loading ? onManage : null,
                      icon: Icon(
                        useManage
                            ? Icons.settings_outlined
                            : Icons.check_circle_outline,
                        size: 20,
                      ),
                      label: Text(label),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: ink,
                        side: BorderSide(
                          color: enabled ? primary.withValues(alpha: 0.45) : line,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TokensStrip.rButton),
                        ),
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          footnote,
          textAlign: TextAlign.center,
          style: TextStyle(color: mute, fontSize: 11.5, height: 1.4),
        ),
      ],
    );
  }
}

class _ActivePlanStatusChip extends StatelessWidget {
  final SubscriptionPlan plan;
  final SubscriptionBillingPeriod billingPeriod;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const _ActivePlanStatusChip({
    required this.plan,
    required this.billingPeriod,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final periodLabel =
        billingPeriod == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';
    return Semantics(
      label: 'Plano ativo ${plan.apiName}, período $periodLabel',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, size: 18, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Plano ${plan.apiName} ativo · visualizando oferta $periodLabel',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageSubscriptionCard extends StatelessWidget {
  final Color primary;
  final Color ink;
  final Color mute;
  final bool isDark;
  final VoidCallback onManage;

  const _ManageSubscriptionCard({
    required this.primary,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Assinatura ativa',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ink,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subscriptionUsesNativeStore
                ? 'Altere renovação, cancele ou troque mensal/anual direto na ${subscriptionChannelLabel()}.'
                : 'Gerencie cobrança e renovação na área de assinatura da web.',
            style: TextStyle(color: ink.withValues(alpha: 0.8), height: 1.45, fontSize: 13),
          ),
          if (subscriptionUsesNativeStore) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Abrir assinaturas do dispositivo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color, softColor;
  final bool isDark;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.softColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
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
    final annual = SubscriptionProducts.referenceAnnualPrice(plano.precoMensal);
    return 'R\$ ${annual.toStringAsFixed(2)}$suffix';
  }
  return 'R\$ ${plano.precoMensal.toStringAsFixed(2)}$suffix';
}
