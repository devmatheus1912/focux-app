import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
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

part 'claude_paywall_layout.dart';

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
    final surface =
        isDark ? EagleTokens.darkBg : Theme.of(context).colorScheme.surface;

    return FxShellScaffold(
      useMesh: false,
      appBar: FxShellAppBar(
        title: 'Planos',
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
          final selDowngrade = selPlan.level < currentPlan.level;
          final isCurrentPlanSelected = selPlan == currentPlan;

          if (selPlan == SubscriptionPlan.ENTERPRISE &&
              currentPlan != SubscriptionPlan.ENTERPRISE &&
              !_enterprisePreviewRequested) {
            _enterprisePreviewRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadEnterprisePreview();
            });
          }

          return ColoredBox(
            color: surface,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
              children: [
                _ClaudePaywallHeader(
                  ink: ink,
                  mute: mute,
                  currentPlan: currentPlan,
                ),
                if (!kIsWeb && subscriptionUsesNativeStore) ...[
                  const SizedBox(height: 28),
                  _ClaudeBillingSegment(
                    period: _billingPeriod,
                    ink: ink,
                    mute: mute,
                    line: line,
                    isDark: isDark,
                    onChanged: (period) {
                      HapticFeedback.selectionClick();
                      setState(() => _billingPeriod = period);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ...paid.map((plano) {
                  final plan = subscriptionPlanFromApi(plano.nome);
                  final product = _productDetails[
                    SubscriptionProducts.productIdFor(plan, _billingPeriod)];
                  final monthlyProduct = _productDetails[
                    SubscriptionProducts.productIdFor(
                      plan,
                      SubscriptionBillingPeriod.monthly,
                    )];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClaudePlanOptionTile(
                      plano: plano,
                      plan: plan,
                      isSelected: plan == selPlan,
                      isCurrent: plan == currentPlan,
                      billingPeriod: _billingPeriod,
                      priceLabel: _formatPrice(plano, product, _billingPeriod),
                      monthlyEquiv:
                          _billingPeriod == SubscriptionBillingPeriod.yearly
                              ? _formatPrice(
                                plano,
                                monthlyProduct,
                                SubscriptionBillingPeriod.monthly,
                              )
                              : null,
                      subtitle: _planSubtitle(plan),
                      ink: ink,
                      mute: mute,
                      line: line,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _selectPlan(plan);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _ClaudeFeaturePanel(
                  plano: selBackend,
                  plan: selPlan,
                  ink: ink,
                  mute: mute,
                  line: line,
                  isDark: isDark,
                ),
                if (_shouldShowEnterpriseTrialCard(
                  selPlan,
                  currentPlan,
                  _trialStatus,
                )) ...[
                  const SizedBox(height: 16),
                  _ClaudeInlineNote(
                    icon: Icons.card_giftcard_outlined,
                    text:
                        subscriptionUsesNativeStore
                            ? 'Teste introdutório configurado na ${subscriptionChannelLabel()}.'
                            : '7 dias grátis neste plano.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                if (isCurrentPlanSelected &&
                    currentPlan != SubscriptionPlan.FREE) ...[
                  const SizedBox(height: 16),
                  _ClaudeInlineNote(
                    icon: Icons.verified_outlined,
                    text:
                        'Plano ${currentPlan.apiName} ativo. Renovação e cancelamento na ${subscriptionChannelLabel()}.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                    onTap:
                        subscriptionUsesNativeStore
                            ? _openSubscriptionManagement
                            : null,
                    actionLabel:
                        subscriptionUsesNativeStore ? 'Abrir loja' : null,
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
                  _ClaudeInlineNote(
                    icon: Icons.info_outline,
                    text:
                        subscriptionUsesNativeStore
                            ? 'Para um plano menor ou cancelamento, use as assinaturas do dispositivo.'
                            : 'Downgrade disponível apenas via suporte.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                if (!_storeAvailable && !kIsWeb) ...[
                  const SizedBox(height: 12),
                  _ClaudeInlineNote(
                    icon: Icons.store_outlined,
                    text: 'Loja do dispositivo indisponível nesta sessão.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  _ClaudeInlineNote(
                    icon: Icons.smartphone_outlined,
                    text:
                        'No celular, assine pela App Store ou Google Play.',
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 20),
                _ClaudeLegalFooter(
                  mute: mute,
                  restoring: _restoringPurchases,
                  onRestore:
                      subscriptionUsesNativeStore ? _restorePurchases : null,
                ),
              ],
            ),
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
    final bg = isDark ? EagleTokens.darkCardHi : EagleTokens.paper;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Text(
        preview.cobrancaImediata
            ? 'Upgrade: cobrança proporcional de R\$ ${preview.valorProporcional.toStringAsFixed(2)} (${preview.diasRestantes} dias restantes no ciclo).'
            : 'Upgrade sem cobrança proporcional imediata neste ciclo.',
        style: TextStyle(color: ink.withValues(alpha: 0.85), height: 1.45, fontSize: 13),
      ),
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
                  ? SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          mode == _AssinaturaCtaMode.syncing
                              ? null
                              : (enabled ? onSubscribe : null),
                      style: FilledButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: mute.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          loading || mode == _AssinaturaCtaMode.syncing
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  )
                  : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: enabled && !loading ? onManage : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(
                          color: enabled ? ink.withValues(alpha: 0.35) : line,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
