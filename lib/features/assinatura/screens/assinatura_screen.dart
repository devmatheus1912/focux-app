import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
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

  // Trial
  TrialStatus? _trialStatus;
  bool _loadingTrial = false;

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
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTrialStatus() async {
    if (mounted) setState(() => _loadingTrial = true);
    try {
      final status = await PlanosRepository(ref.read(apiClientProvider)).getTrialStatus();
      if (mounted) setState(() { _trialStatus = status; _loadingTrial = false; });
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
      _productIds.values.toSet(),
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
            if (mounted) setState(() { _loadingCheckout = false; _syncingPurchase = false; });
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
      if (purchasedPlan == SubscriptionPlan.ENTERPRISE) {
        final repo = PlanosRepository(ref.read(apiClientProvider));
        final preview = await repo.previewEnterpriseUpgrade();
        final metadata = _metadataFromPurchase(purchase);
        final billingCycleEndsAt = _estimateBillingCycleEnd(purchase);

        await repo.activateEnterprise(
          metadata.toEnterpriseActivationPayload(billingCycleEndsAt: billingCycleEndsAt),
        );

        if (mounted) setState(() => _enterprisePreview = preview);
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

      if (mounted) safePopOrGo(context, '/planos');
    } catch (error) {
      _finishPurchaseFlowWithError('Não foi possível sincronizar a assinatura: $error');
    } finally {
      if (mounted) setState(() { _syncingPurchase = false; _loadingCheckout = false; });
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
      transactionId: purchaseId?.isNotEmpty == true ? purchaseId! : 'txn-${now.microsecondsSinceEpoch}',
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
      if (entry.value == productId) return entry.key;
    }
    return null;
  }

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    if (_selectedPlanName == plan.apiName) return;

    setState(() {
      _selectedPlanName = plan.apiName;
      if (plan != SubscriptionPlan.ENTERPRISE) _enterprisePreview = null;
    });

    if (plan == SubscriptionPlan.ENTERPRISE) await _loadEnterprisePreview();
  }

  Future<void> _loadEnterprisePreview() async {
    try {
      final preview = await PlanosRepository(ref.read(apiClientProvider)).previewEnterpriseUpgrade();
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
        final checkoutUrl = await AssinaturaRepository(ref.read(apiClientProvider)).criarPreferencia(planId);
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, webOnlyWindowName: '_self');
      } catch (error) {
        _finishPurchaseFlowWithError('Erro ao gerar checkout web: $error');
      }
      return;
    }

    if (!_storeAvailable) {
      _finishPurchaseFlowWithError('A loja de aplicativos não está disponível neste dispositivo.');
      return;
    }

    final productId = _productIds[plan];
    if (productId == null) {
      _finishPurchaseFlowWithError('Plano selecionado não possui produto válido.');
      return;
    }

    ProductDetails? product = _productDetails[productId];
    if (product == null) {
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      if (!mounted) return;
      if (response.productDetails.isEmpty) {
        _finishPurchaseFlowWithError('Produto ainda não configurado na loja para este plano.');
        return;
      }
      product = response.productDetails.first;
      setState(() => _productDetails = {..._productDetails, productId: product!});
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
    setState(() { _loadingCheckout = false; _syncingPurchase = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safePopOrGo(context, '/planos'),
        ),
        title: const Text('Assinatura'),
      ),
      body: planosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (planos) {
          final sortedPlans = [...planos]..sort(
              (a, b) => subscriptionPlanFromApi(a.nome).level
                  .compareTo(subscriptionPlanFromApi(b.nome).level),
            );

          final selectedPlan = subscriptionPlanFromApi(_selectedPlanName);
          final selectedBackendPlan = sortedPlans.firstWhere(
            (plan) => subscriptionPlanFromApi(plan.nome) == selectedPlan,
            orElse: () => sortedPlans.first,
          );

          final isCurrentPlan = selectedPlan == currentPlan;
          final isDowngrade = selectedPlan.level < currentPlan.level;
          final ctaEnabled = selectedPlan != SubscriptionPlan.FREE &&
              !isCurrentPlan &&
              !isDowngrade &&
              !_loadingCheckout &&
              !_syncingPurchase;

          final ctaLabel = _syncingPurchase
              ? 'Sincronizando assinatura...'
              : selectedPlan == SubscriptionPlan.ENTERPRISE
                  ? 'Assinar Enterprise'
                  : (_trialStatus?.trialUsed == false)
                      ? 'Iniciar período gratuito'
                      : 'Assinar Premium';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // ── Header ────────────────────────────────────────────────
              Text(
                'Escolha como você quer escalar o Focux.',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                kIsWeb
                    ? 'No app, as compras são processadas pela App Store ou Google Play. No plano Enterprise, a ativação sincroniza automaticamente com o backend.'
                    : 'As compras são iniciadas pela loja do dispositivo e o plano Enterprise sincroniza automaticamente com o backend.',
                style: TextStyle(color: mute, height: 1.45),
              ),
              const SizedBox(height: 18),

              // ── Plano cards ───────────────────────────────────────────
              ...sortedPlans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanoCard(
                    plano: plan,
                    currentPlan: currentPlan,
                    selectedPlan: selectedPlan,
                    productDetails: _productDetails[_productIds[subscriptionPlanFromApi(plan.nome)]],
                    trialStatus: _trialStatus,
                    onTap: () => _selectPlan(subscriptionPlanFromApi(plan.nome)),
                    isDark: isDark,
                  ),
                ),
              ),

              // ── Trial card (PREMIUM selecionado) ──────────────────────
              if (selectedPlan == SubscriptionPlan.PREMIUM) ...[
                const SizedBox(height: 4),
                _TrialInfoCard(
                  trialStatus: _trialStatus,
                  loading: _loadingTrial,
                  isDark: isDark,
                  cardBg: cardBg,
                  ink: ink,
                  mute: mute,
                  line: line,
                ),
              ],

              // ── Enterprise preview ─────────────────────────────────────
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
                          const Icon(Icons.receipt_long_outlined, color: EagleTokens.brand, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Preview da cobrança Enterprise',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _enterprisePreview!.cobrancaImediata
                            ? 'Cobrança proporcional imediata: R\$ ${_enterprisePreview!.valorProporcional.toStringAsFixed(2)}.'
                            : 'Sem cobrança proporcional imediata para este upgrade.',
                        style: TextStyle(color: ink, height: 1.45),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dias restantes considerados: ${_enterprisePreview!.diasRestantes}  |  Diferença diária: R\$ ${_enterprisePreview!.diferencaDiaria.toStringAsFixed(2)}',
                        style: TextStyle(color: mute, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Resumo ─────────────────────────────────────────────────
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _ResumoRow(label: 'Plano atual', value: currentPlan.apiName, ink: ink, mute: mute),
                    const SizedBox(height: 4),
                    _ResumoRow(label: 'Selecionado', value: selectedPlan.apiName, ink: ink, mute: mute),
                    const SizedBox(height: 4),
                    _ResumoRow(
                      label: 'Preço',
                      value: _formatPrice(selectedBackendPlan, _productDetails[_productIds[selectedPlan]]),
                      ink: EagleTokens.brand,
                      mute: mute,
                      valueBold: true,
                    ),
                    if (isDowngrade) ...[
                      const SizedBox(height: 10),
                      _InfoBanner(
                        icon: Icons.info_outline,
                        text: 'Downgrade não está disponível aqui. Entre em contato com o suporte.',
                        color: EagleTokens.warn,
                        softColor: EagleTokens.warnSoft,
                        isDark: isDark,
                      ),
                    ],
                    if (!_storeAvailable && !kIsWeb) ...[
                      const SizedBox(height: 10),
                      _InfoBanner(
                        icon: Icons.store_outlined,
                        text: 'A loja do dispositivo não está disponível nesta sessão. O fluxo de compra real exige App Store ou Google Play.',
                        color: mute,
                        softColor: isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
                        isDark: isDark,
                      ),
                    ],
                    if (kIsWeb) ...[
                      const SizedBox(height: 10),
                      _InfoBanner(
                        icon: Icons.smartphone_outlined,
                        text: 'A loja do dispositivo não está disponível na versão web. Para assinar, acesse o app no seu celular.',
                        color: mute,
                        softColor: isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              // ── CTA ────────────────────────────────────────────────────
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
                    disabledForegroundColor: mute,
                  ),
                  onPressed: ctaEnabled
                      ? () => _startCheckout(selectedPlan, selectedBackendPlan.id)
                      : null,
                  child: _loadingCheckout || _syncingPurchase
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(ctaLabel),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCurrentPlan
                    ? 'Este plano já está ativo na sua conta.'
                    : isDowngrade
                        ? 'Selecione um plano superior ao atual para continuar.'
                        : selectedPlan == SubscriptionPlan.FREE
                            ? 'O plano gratuito não requer assinatura.'
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

// ─── Trial Info Card ─────────────────────────────────────────────────────────

class _TrialInfoCard extends StatelessWidget {
  final TrialStatus? trialStatus;
  final bool loading;
  final bool isDark;
  final Color cardBg, ink, mute, line;

  const _TrialInfoCard({
    required this.trialStatus,
    required this.loading,
    required this.isDark,
    required this.cardBg,
    required this.ink,
    required this.mute,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final trialUsed = trialStatus?.trialUsed ?? false;
    final trialAtivo = trialStatus?.trialAtivo ?? false;
    final diasRestantes = trialStatus?.diasRestantes ?? 0;
    final trialEndsAt = trialStatus?.trialEndsAt;

    // Cores
    final accentColor = trialUsed
        ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
        : (isDark ? const Color(0xFF6FE296) : EagleTokens.good);
    final softColor = trialUsed
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
              text: '7 dias grátis incluídos neste plano.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon: Icons.credit_card_outlined,
              text: 'É obrigatório cadastrar um cartão de crédito para ativar o período gratuito.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon: Icons.lock_outline,
              text: 'Não haverá nenhuma cobrança até o encerramento dos 7 dias. Cancele a qualquer momento antes disso sem custo.',
              accentColor: accentColor,
            ),
          ] else if (trialAtivo) ...[
            _TrialRow(
              icon: Icons.timer_outlined,
              text: 'Período gratuito ativo — $diasRestantes dias restantes${trialEndsAt != null ? ' (encerra em ${_formatDate(trialEndsAt)})' : ''}.',
              accentColor: accentColor,
            ),
            const SizedBox(height: 8),
            _TrialRow(
              icon: Icons.credit_card_outlined,
              text: 'Sua cobrança começará automaticamente ao fim do trial. Cancele antes se não quiser continuar.',
              accentColor: accentColor,
            ),
          ] else ...[
            _TrialRow(
              icon: Icons.info_outline,
              text: 'Você já utilizou o período gratuito. A cobrança começa imediatamente ao assinar.',
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

  const _TrialRow({required this.icon, required this.text, required this.accentColor});

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

// ─── Plano Card ───────────────────────────────────────────────────────────────

class _PlanoCard extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;
  final ProductDetails? productDetails;
  final TrialStatus? trialStatus;
  final VoidCallback onTap;
  final bool isDark;

  const _PlanoCard({
    required this.plano,
    required this.currentPlan,
    required this.selectedPlan,
    required this.productDetails,
    required this.trialStatus,
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
      SubscriptionPlan.FREE       => isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
      SubscriptionPlan.PREMIUM    => EagleTokens.brand,
      SubscriptionPlan.ENTERPRISE => const Color(0xFFC49A2A),
    };

    // Trial badge PREMIUM
    final showTrialBadge = plan == SubscriptionPlan.PREMIUM &&
        (trialStatus == null || !trialStatus!.trialUsed);

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
              ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 8))]
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
                if (showTrialBadge)
                  _Badge(
                    label: '7 dias grátis',
                    background: EagleTokens.goodSoft,
                    foreground: EagleTokens.good,
                  ),
                if (showTrialBadge && (isCurrent || isSelected))
                  const SizedBox(width: 6),
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
              style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _FeatureRow(
              label: plano.limiteAlunos == null ? 'Alunos ilimitados' : 'Até ${plano.limiteAlunos} alunos',
              active: true, accent: accent, mute: mute,
            ),
            _FeatureRow(label: 'White-label',   active: plano.temWhiteLabel,  accent: accent, mute: mute),
            _FeatureRow(label: 'Financeiro',    active: plano.temFinanceiro,  accent: accent, mute: mute),
            _FeatureRow(label: 'Agenda',        active: plano.temAgenda,      accent: accent, mute: mute),
            _FeatureRow(label: 'Relatórios',    active: plano.temRelatorios,  accent: accent, mute: mute),
            _FeatureRow(
              label: 'IA Copiloto',
              active: plan != SubscriptionPlan.FREE,
              accent: accent, mute: mute,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent, mute;

  const _FeatureRow({required this.label, required this.active, required this.accent, required this.mute});

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
            child: Text(label, style: TextStyle(color: active ? null : mute)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background, foreground;

  const _Badge({required this.label, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final String label, value;
  final Color ink, mute;
  final bool valueBold;

  const _ResumoRow({
    required this.label,
    required this.value,
    required this.ink,
    required this.mute,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: mute, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
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
            child: Text(text, style: TextStyle(color: color, fontSize: 12.5, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatPrice(Plano plano, ProductDetails? productDetails) {
  if (plano.precoMensal == 0) return 'Grátis';
  if (productDetails != null) return '${productDetails.price}/mês';
  return 'R\$ ${plano.precoMensal.toStringAsFixed(2)}/mês';
}
