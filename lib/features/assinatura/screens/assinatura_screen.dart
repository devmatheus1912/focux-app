import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/assinatura_repository.dart';
import '../providers/assinatura_provider.dart';

class AssinaturaScreen extends ConsumerStatefulWidget {
  final String? initialPlan;

  const AssinaturaScreen({super.key, this.initialPlan});

  @override
  ConsumerState<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends ConsumerState<AssinaturaScreen> {
  static const Map<SubscriptionPlan, String> _productIds = {
    SubscriptionPlan.PREMIUM: 'focux_premium_monthly',
    SubscriptionPlan.ENTERPRISE: 'focux_enterprise_monthly',
  };

  final Set<String> _handledPurchases = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  String? _selectedPlanName;
  bool _loadingCheckout = false;
  bool _syncingPurchase = false;
  bool _storeAvailable = false;
  Map<String, ProductDetails> _productDetails = const {};
  EnterpriseUpgradePreview? _enterprisePreview;

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
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    if (kIsWeb) {
      if (mounted) setState(() => _storeAvailable = false);
      return;
    }
    
    final available = await InAppPurchase.instance.isAvailable();
    if (!mounted) return;

    setState(() => _storeAvailable = available);

    if (!available) {
      return;
    }

    final response = await InAppPurchase.instance.queryProductDetails(
      _productIds.values.toSet(),
    );

    if (!mounted) return;

    setState(() {
      _productDetails = {
        for (final item in response.productDetails) item.id: item,
      };
    });
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            if (mounted) {
              setState(() {
                _loadingCheckout = true;
              });
            }
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

    if (_handledPurchases.contains(purchaseKey)) {
      return;
    }

    final purchasedPlan = _planForProductId(purchase.productID);
    if (purchasedPlan == null) {
      _finishPurchaseFlowWithError('Produto recebido nao e suportado.');
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
      if (purchasedPlan == SubscriptionPlan.ENTERPRISE) {
        final repo = PlanosRepository(ref.read(apiClientProvider));
        final preview = await repo.previewEnterpriseUpgrade();
        final metadata = _metadataFromPurchase(purchase);
        final billingCycleEndsAt = _estimateBillingCycleEnd(purchase);

        await repo.activateEnterprise(
          metadata.toEnterpriseActivationPayload(
            billingCycleEndsAt: billingCycleEndsAt,
          ),
        );

        if (mounted) {
          setState(() => _enterprisePreview = preview);
        }
      }

      ref.invalidate(perfilProvider);
      ref.invalidate(planosProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            purchasedPlan == SubscriptionPlan.ENTERPRISE
                ? 'Assinatura Enterprise sincronizada com sucesso.'
                : 'Assinatura Premium iniciada com sucesso.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      _finishPurchaseFlowWithError(
        'Nao foi possivel sincronizar a assinatura: $error',
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

  SubscriptionMetadata _metadataFromPurchase(PurchaseDetails purchase) {
    final now = DateTime.now();
    final rawToken = purchase.verificationData.serverVerificationData.trim();
    final purchaseId = purchase.purchaseID?.trim();

    return SubscriptionMetadata(
      platform: inferPlatformName(),
      productId: purchase.productID,
      subscriptionToken: rawToken.isNotEmpty
          ? rawToken
          : 'purchase-${purchaseId ?? now.millisecondsSinceEpoch}',
      transactionId:
          purchaseId?.isNotEmpty == true ? purchaseId! : 'txn-${now.microsecondsSinceEpoch}',
    );
  }

  DateTime _estimateBillingCycleEnd(PurchaseDetails purchase) {
    final transactionDateMs = int.tryParse(purchase.transactionDate ?? '');
    final start = transactionDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(transactionDateMs)
        : DateTime.now();
    return start.add(const Duration(days: 30));
  }

  SubscriptionPlan? _planForProductId(String productId) {
    for (final entry in _productIds.entries) {
      if (entry.value == productId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    if (_selectedPlanName == plan.apiName) {
      return;
    }

    setState(() {
      _selectedPlanName = plan.apiName;
      if (plan != SubscriptionPlan.ENTERPRISE) {
        _enterprisePreview = null;
      }
    });

    if (plan == SubscriptionPlan.ENTERPRISE) {
      await _loadEnterprisePreview();
    }
  }

  Future<void> _loadEnterprisePreview() async {
    try {
      final preview = await PlanosRepository(
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
    if (_loadingCheckout || _syncingPurchase) {
      return;
    }

    if (kIsWeb) {
      setState(() => _loadingCheckout = true);
      try {
        final checkoutUrl = await AssinaturaRepository(ref.read(apiClientProvider)).criarPreferencia(planId);
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, webOnlyWindowName: '_self');
      } catch (error) {
        _finishPurchaseFlowWithError('Erro ao gerar checkout web: $error');
      }
      return;
    }

    if (!_storeAvailable) {
      _finishPurchaseFlowWithError(
        'A loja de aplicativos nao esta disponivel neste dispositivo.',
      );
      return;
    }

    final productId = _productIds[plan];
    if (productId == null) {
      _finishPurchaseFlowWithError('Plano selecionado nao possui produto valido.');
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
          'Produto ainda nao configurado na loja para este plano.',
        );
        return;
      }
      product = response.productDetails.first;
      setState(() {
        _productDetails = {
          ..._productDetails,
          productId: product!,
        };
      });
    }

    setState(() => _loadingCheckout = true);

    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      _finishPurchaseFlowWithError(
        'Erro ao iniciar a compra na loja: $error',
      );
    }
  }

  void _finishPurchaseFlowWithError(String message) {
    if (!mounted) return;
    setState(() {
      _loadingCheckout = false;
      _syncingPurchase = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final planosAsync = ref.watch(planosProvider);

    _selectedPlanName ??= widget.initialPlan?.trim().toUpperCase() ?? currentPlan.apiName;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Assinatura'),
      ),
      body: planosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (planos) {
          final sortedPlans = [...planos]..sort(
              (a, b) => subscriptionPlanFromApi(
                a.nome,
              ).level.compareTo(subscriptionPlanFromApi(b.nome).level),
            );

          final selectedPlan = subscriptionPlanFromApi(_selectedPlanName);
          final selectedBackendPlan = sortedPlans.firstWhere(
            (plan) => subscriptionPlanFromApi(plan.nome) == selectedPlan,
            orElse: () => sortedPlans.first,
          );

          final isCurrentPlan = selectedPlan == currentPlan;
          final ctaEnabled = selectedPlan != SubscriptionPlan.FREE &&
              !isCurrentPlan &&
              !_loadingCheckout &&
              !_syncingPurchase;

          final ctaLabel = _syncingPurchase
              ? 'Sincronizando assinatura...'
              : selectedPlan == SubscriptionPlan.ENTERPRISE
                  ? 'Assinar Enterprise'
                  : 'Assinar Premium';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                'Escolha como voce quer escalar o Focux.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'As compras sao iniciadas pela loja do dispositivo e o plano Enterprise ainda sincroniza automaticamente com o backend.',
                style: TextStyle(color: mute, height: 1.45),
              ),
              const SizedBox(height: 18),
              ...sortedPlans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanoCard(
                    plano: plan,
                    currentPlan: currentPlan,
                    selectedPlan: selectedPlan,
                    productDetails: _productDetails[
                        _productIds[subscriptionPlanFromApi(plan.nome)]],
                    onTap: () => _selectPlan(subscriptionPlanFromApi(plan.nome)),
                    isDark: isDark,
                  ),
                ),
              ),
              if (selectedPlan == SubscriptionPlan.ENTERPRISE &&
                  _enterprisePreview != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: EagleTokens.brand,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preview da cobranca Enterprise',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _enterprisePreview!.cobrancaImediata
                            ? 'Cobranca proporcional imediata: R\$ ${_enterprisePreview!.valorProporcional.toStringAsFixed(2)}.'
                            : 'Sem cobranca proporcional imediata para este upgrade.',
                        style: TextStyle(color: ink, height: 1.45),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dias restantes considerados: ${_enterprisePreview!.diasRestantes}  |  Diferenca diaria: R\$ ${_enterprisePreview!.diferencaDiaria.toStringAsFixed(2)}',
                        style: TextStyle(color: mute, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do plano',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Plano atual: ${currentPlan.apiName}',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecionado: ${selectedPlan.apiName}',
                      style: TextStyle(color: mute),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(
                        selectedBackendPlan,
                        _productDetails[_productIds[selectedPlan]],
                      ),
                      style: TextStyle(color: EagleTokens.brand),
                    ),
                    if (!_storeAvailable) ...[
                      const SizedBox(height: 10),
                      Text(
                        'A loja do dispositivo nao esta disponivel nesta sessao. O fluxo de compra real exige App Store ou Google Play.',
                        style: TextStyle(color: mute, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: ctaEnabled
                      ? () => _startCheckout(selectedPlan, selectedBackendPlan.id)
                      : null,
                  child: _loadingCheckout || _syncingPurchase
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(ctaLabel),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCurrentPlan
                    ? 'Este plano ja esta ativo na sua conta.'
                    : 'O fechamento da compra acontece pela loja do dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 12.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanoCard extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;
  final ProductDetails? productDetails;
  final VoidCallback onTap;
  final bool isDark;

  const _PlanoCard({
    required this.plano,
    required this.currentPlan,
    required this.selectedPlan,
    required this.productDetails,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final plan = subscriptionPlanFromApi(plano.nome);
    final isSelected = plan == selectedPlan;
    final isCurrent = plan == currentPlan;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = switch (plan) {
      SubscriptionPlan.FREE => EagleTokens.inkMute,
      SubscriptionPlan.PREMIUM => EagleTokens.brand,
      SubscriptionPlan.ENTERPRISE => const Color(0xFFC49A2A),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected || isCurrent ? accent : line,
            width: isSelected || isCurrent ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.apiName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected || isCurrent ? accent : ink,
                        ),
                  ),
                ),
                if (isCurrent)
                  _Badge(
                    label: 'Atual',
                    background: accent.withValues(alpha: 0.14),
                    foreground: accent,
                  )
                else if (isSelected)
                  _Badge(
                    label: 'Selecionado',
                    background: accent.withValues(alpha: 0.14),
                    foreground: accent,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatPrice(plano, productDetails),
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _FeatureRow(
              label: plano.limiteAlunos == null
                  ? 'Alunos ilimitados'
                  : 'Ate ${plano.limiteAlunos} alunos',
              active: true,
              accent: accent,
              mute: mute,
            ),
            _FeatureRow(
              label: 'White-label',
              active: plano.temWhiteLabel,
              accent: accent,
              mute: mute,
            ),
            _FeatureRow(
              label: 'Financeiro',
              active: plano.temFinanceiro,
              accent: accent,
              mute: mute,
            ),
            _FeatureRow(
              label: 'Agenda',
              active: plano.temAgenda,
              accent: accent,
              mute: mute,
            ),
            _FeatureRow(
              label: 'Relatorios',
              active: plano.temRelatorios,
              accent: accent,
              mute: mute,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final Color mute;

  const _FeatureRow({
    required this.label,
    required this.active,
    required this.accent,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: active ? accent : mute,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active ? null : mute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

String _formatPrice(Plano plano, ProductDetails? productDetails) {
  if (plano.precoMensal == 0) {
    return 'Gratis';
  }

  if (productDetails != null) {
    return '${productDetails.price}/mes';
  }

  return 'R\$ ${plano.precoMensal.toStringAsFixed(2)}/mes';
}
