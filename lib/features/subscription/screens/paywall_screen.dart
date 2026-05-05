import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../models/subscription_plan.dart';
import '../services/iap_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _submitting = false;
  bool _restoringPurchases = false;
  late final List<Map<String, dynamic>> _planos;
  int _selected = 2;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(ProductEvents.paywallOpened);
    _planos = [
      {
        'id': 0,
        'nome': 'FREE',
        'preco': null,
        'trial': null,
        'cor': EagleTokens.inkMute,
        'tag': null,
        'sub': 'Para começar',
        'plan': SubscriptionPlan.FREE,
        'features': [
          {'ok': true, 'label': 'Até 5 alunos ativos'},
          {'ok': true, 'label': 'Treinos básicos'},
          {'ok': false, 'label': 'Financeiro'},
          {'ok': false, 'label': 'IA Copiloto'},
          {'ok': false, 'label': 'Landing Page'},
          {'ok': false, 'label': 'Migracao Magica'},
        ],
      },
      {
        'id': 1,
        'nome': 'PREMIUM',
        'preco': '79,00',
        'trial': null,
        'cor': null,
        'tag': 'MAIS POPULAR',
        'sub': 'Para consultores sérios',
        'plan': SubscriptionPlan.PREMIUM,
        'features': [
          {'ok': true, 'label': 'Até 20 alunos ativos'},
          {'ok': true, 'label': 'Financeiro e cobrancas'},
          {'ok': true, 'label': 'CRM Kanban de Leads'},
          {'ok': true, 'label': 'Migração Mágica IA'},
          {'ok': false, 'label': 'Landing Page white-label'},
          {'ok': false, 'label': 'IA ilimitada'},
        ],
      },
      {
        'id': 2,
        'nome': 'ENTERPRISE',
        'preco': '149,90',
        'trial': 7,
        'cor': const Color(0xFFC49A2A),
        'tag': 'ESCALA TOTAL',
        'sub': 'Para quem quer crescer',
        'plan': SubscriptionPlan.ENTERPRISE,
        'features': [
          {'ok': true, 'label': 'Alunos ilimitados'},
          {'ok': true, 'label': 'IA Copiloto completa'},
          {'ok': true, 'label': 'Landing Page white-label'},
          {'ok': true, 'label': 'Motor anti-churn e prova social'},
          {'ok': true, 'label': 'Analytics avancado'},
          {'ok': true, 'label': 'Suporte prioritario'},
        ],
      },
    ];
  }

  Color _planAccent(SubscriptionPlan plan, Color primary, bool isDark) {
    return switch (plan) {
      SubscriptionPlan.FREE =>
        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
      SubscriptionPlan.PREMIUM => primary,
      SubscriptionPlan.ENTERPRISE => const Color(0xFFC49A2A),
    };
  }

  Future<void> _handlePrimaryAction() async {
    final perfil = ref.read(perfilProvider).valueOrNull;
    final selectedPlan = _planos[_selected]['plan'] as SubscriptionPlan;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;
    final trialActive =
        perfil?.trialEndsAt != null &&
        perfil!.trialEndsAt!.isAfter(DateTime.now());
    final trialOfferAvailable =
        selectedPlan == SubscriptionPlan.ENTERPRISE &&
        !trialUsed &&
        !trialActive;
    final blocksBecauseCurrent =
        selectedPlan == currentPlan && !trialOfferAvailable;

    if (selectedPlan == SubscriptionPlan.FREE ||
        blocksBecauseCurrent ||
        _submitting) {
      return;
    }

    AnalyticsService.instance.track(
      ProductEvents.paywallCtaTapped,
      props: {'plan': selectedPlan.apiName, 'trialUsed': trialUsed},
    );

    if (selectedPlan == SubscriptionPlan.PREMIUM) {
      if (!mounted) return;
      await context.push(
        '/assinatura',
        extra: SubscriptionPlan.PREMIUM.apiName,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = true);
    await context.push(
      '/assinatura',
      extra: SubscriptionPlan.ENTERPRISE.apiName,
    );
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _restorePurchases() async {
    if (_restoringPurchases) return;

    setState(() => _restoringPurchases = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando compras anteriores...')),
    );

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A loja do dispositivo nao esta disponivel.'),
          ),
        );
        return;
      }

      if (result.hasVerifiedPurchases) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas com sucesso.')),
        );
        return;
      }

      if (result.errors.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.errors.first.message)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma compra anterior encontrada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao restaurar compras: $error')),
      );
    } finally {
      if (mounted) setState(() => _restoringPurchases = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;
    final trialActive =
        perfil?.trialEndsAt != null &&
        perfil!.trialEndsAt!.isAfter(DateTime.now());

    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.light;
    const bg = Color(0xFF071126);
    const cardBg = Color(0xFF111A2F);
    const ink = Colors.white;
    const mute = Color(0xFFB9C4D8);
    const line = Color(0x263B82F6);
    const brand = Color(0xFF4D78FF);
    final brandDeep = BrandPalette.deep(brand);

    final pl = _planos[_selected];
    final selectedPlan = pl['plan'] as SubscriptionPlan;
    final plCor = _planAccent(selectedPlan, brand, isDark);
    final trialOfferAvailable =
        selectedPlan == SubscriptionPlan.ENTERPRISE &&
        !trialUsed &&
        !trialActive;
    final isCurrentPlan = selectedPlan == currentPlan && !trialOfferAvailable;

    String ctaLabel;
    if (selectedPlan == SubscriptionPlan.FREE) {
      ctaLabel = 'Plano atual';
    } else if (isCurrentPlan) {
      ctaLabel = 'Plano atual';
    } else if (selectedPlan == SubscriptionPlan.PREMIUM) {
      ctaLabel = 'Assinar Premium';
    } else if (!trialUsed) {
      ctaLabel = 'Testar 7 dias grátis';
    } else {
      ctaLabel = 'Assinar Enterprise';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/dashboard/personal'),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.96),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trialOfferAvailable) ...[
                Text(
                  'Cancele antes dos 7 dias. Nada sera cobrado no cartao.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (selectedPlan == SubscriptionPlan.FREE || isCurrentPlan)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : EagleTokens.lineSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isCurrentPlan ? 'Plano atual' : 'Plano gratuito',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: mute,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _submitting ? null : _handlePrimaryAction,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient:
                          selectedPlan == SubscriptionPlan.ENTERPRISE
                              ? const LinearGradient(
                                colors: [Color(0xFFC49A2A), Color(0xFF7A5C0A)],
                              )
                              : LinearGradient(colors: [brand, brandDeep]),
                      boxShadow: [
                        BoxShadow(
                          color: plCor.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        _submitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                          !trialUsed
                                      ? Icons.card_giftcard_rounded
                                      : Icons.star_border,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                          !trialUsed
                                      ? 'Testar 7 dias grátis'
                                      : ctaLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 126),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFD76A),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'TRIAL ENTERPRISE',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFFFFD76A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Desbloqueie o Focux completo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: 0,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Teste alunos ilimitados, IA completa, landing page, marca própria e automações antes de pagar.',
                    style: TextStyle(fontSize: 13, color: mute, height: 1.45),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children:
                    _planos.map((p) {
                      final isSelected = _selected == p['id'];
                      final cColor = _planAccent(
                        p['plan'] as SubscriptionPlan,
                        brand,
                        isDark,
                      );
                      return Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(() => _selected = p['id'] as int),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? cColor
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  isSelected ? null : Border.all(color: line),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: cColor.withValues(alpha: 0.27),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                      : [],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  p['nome'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : ink,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['preco'] != null
                                      ? 'R\$ ${p['preco']}'
                                      : 'Grátis',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isSelected
                                            ? Colors.white.withValues(
                                              alpha: 0.75,
                                            )
                                            : mute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: plCor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: plCor.withValues(alpha: 0.33),
                      blurRadius: 40,
                      spreadRadius: -16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  color: cardBg,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        color:
                            pl['id'] == 0
                                ? (isDark
                                    ? EagleTokens.darkCard
                                    : const Color(0xFFF8F8F6))
                                : null,
                        gradient:
                            pl['id'] > 0
                                ? LinearGradient(
                                  colors: [
                                    plCor.withValues(alpha: 0.93),
                                    pl['id'] == 1
                                        ? brandDeep
                                        : const Color(0xFF3A2600),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                      ),
                      child: Stack(
                        children: [
                          if (pl['id'] > 0)
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Opacity(
                                opacity: 0.08,
                                child: Icon(
                                  Icons.star,
                                  size: 118,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pl['tag'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        pl['tag'] as String,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                'Plano ${pl['nome']}',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: pl['id'] > 0 ? Colors.white : ink,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pl['sub'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      pl['id'] > 0
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : mute,
                                ),
                              ),
                              if (pl['preco'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        'R\$ ${pl['preco']}',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '/mês',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (pl['trial'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${pl['trial']} dias grátis',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children:
                            (pl['features'] as List<dynamic>)
                                .asMap()
                                .entries
                                .map((entry) {
                                  final f = entry.value as Map<String, dynamic>;
                                  final isOk = f['ok'] as bool;
                                  return Container(
                                    height: 40,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isOk
                                              ? (isDark
                                                  ? EagleTokens.goodSoft
                                                      .withValues(alpha: 0.15)
                                                  : EagleTokens.goodSoft)
                                              : (isDark
                                                  ? EagleTokens.darkCardHi
                                                  : EagleTokens.lineSoft),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isOk
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: isOk ? EagleTokens.good : mute,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            f['label'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isOk ? ink : mute,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedPlan != SubscriptionPlan.FREE)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                    !trialUsed
                                ? const Color(0xFF112D23)
                                : EagleTokens.darkCardHi,
                        border: Border.all(
                          color:
                              selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                      !trialUsed
                                  ? const Color(0xFF2E8B57)
                                  : line,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 17,
                            color:
                                selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                        !trialUsed
                                    ? EagleTokens.good
                                    : mute,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                      !trialUsed
                                  ? 'Teste por 7 dias. A loja pede cartao para ativar, mas voce pode cancelar antes do fim do periodo e nao tera cobranca.'
                                  : 'Compra gerenciada pela loja do dispositivo.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFE8FFF0),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: _restoringPurchases ? null : _restorePurchases,
                      child: Text(
                        'Restaurar compras',
                        style: TextStyle(
                          fontSize: 13,
                          color: mute,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
