import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../models/subscription_plan.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _submitting = false;
  late final List<Map<String, dynamic>> _planos;
  int _selected = 1;

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
        'trial': 5,
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
        'trial': 5,
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
    final repo = PlanosRepository(ref.read(apiClientProvider));
    final selectedPlan = _planos[_selected]['plan'] as SubscriptionPlan;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;

    if (selectedPlan == SubscriptionPlan.FREE ||
        selectedPlan == currentPlan ||
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

    if (!trialUsed) {
      setState(() => _submitting = true);
      try {
        await repo.startTrial(
          payload:
              buildLocalSubscriptionMetadata(
                productId: 'focux_enterprise_trial',
              ).toTrialPayload(),
        );
        ref.invalidate(perfilProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trial Enterprise ativado por 5 dias.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao ativar trial: $e')));
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    if (!mounted) return;
    await context.push(
      '/assinatura',
      extra: SubscriptionPlan.ENTERPRISE.apiName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilProvider).valueOrNull;
    final currentPlan = subscriptionPlanFromApi(perfil?.plano);
    final trialUsed = perfil?.trialUsed ?? false;

    final currentIndex = _planos.indexWhere(
      (item) => item['plan'] == currentPlan,
    );
    if (currentIndex >= 0 && !_submitting) {
      _selected = currentIndex;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);

    final pl = _planos[_selected];
    final selectedPlan = pl['plan'] as SubscriptionPlan;
    final plCor = _planAccent(selectedPlan, brand, isDark);
    final isCurrentPlan = selectedPlan == currentPlan;

    String ctaLabel;
    if (selectedPlan == SubscriptionPlan.FREE) {
      ctaLabel = 'Plano atual';
    } else if (isCurrentPlan) {
      ctaLabel = 'Plano atual';
    } else if (selectedPlan == SubscriptionPlan.PREMIUM) {
      ctaLabel = 'Assinar Premium';
    } else if (!trialUsed) {
      ctaLabel = 'Começar 5 dias grátis';
    } else {
      ctaLabel = 'Assinar Enterprise';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolua seu plano',
                    style: TextStyle(
                      fontSize: 11,
                      color: brand,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escolha o plano\nideal para você',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '5 dias grátis e cancelamento quando quiser',
                    style: TextStyle(fontSize: 14, color: mute, height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                    fontSize: 12,
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
                                    fontSize: 11,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
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
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26),
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
                                  size: 160,
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
                                  margin: const EdgeInsets.only(bottom: 12),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: pl['id'] > 0 ? Colors.white : ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pl['sub'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      pl['id'] > 0
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : mute,
                                ),
                              ),
                              if (pl['preco'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        'R\$ ${pl['preco']}',
                                        style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '/mês',
                                        style: TextStyle(
                                          fontSize: 13,
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
                                  margin: const EdgeInsets.only(top: 10),
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
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(26),
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
                                    height: 52,
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
                                          size: 18,
                                          color: isOk ? EagleTokens.good : mute,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            f['label'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedPlan == SubscriptionPlan.FREE || isCurrentPlan)
                    Container(
                      height: 52,
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
                          fontWeight: FontWeight.w600,
                          color: mute,
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: _submitting ? null : _handlePrimaryAction,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient:
                              selectedPlan == SubscriptionPlan.ENTERPRISE
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFFC49A2A),
                                      Color(0xFF7A5C0A),
                                    ],
                                  )
                                  : LinearGradient(colors: [brand, brandDeep]),
                          boxShadow: [
                            BoxShadow(
                              color: plCor.withValues(alpha: 0.4),
                              blurRadius: 20,
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
                                    const Icon(
                                      Icons.star_border,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ctaLabel,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  if (selectedPlan != SubscriptionPlan.FREE)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        selectedPlan == SubscriptionPlan.ENTERPRISE &&
                                !trialUsed
                            ? 'Após o trial, a assinatura mensal passa a valer normalmente.'
                            : 'Compra gerenciada pela loja do dispositivo.',
                        style: TextStyle(fontSize: 12, color: mute),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verificando compras anteriores...'),
                          ),
                        );
                        // IAP restore handled by store
                        try {
                          final repo = PlanosRepository(ref.read(apiClientProvider));
                          await repo.syncSubscription();
                          ref.invalidate(perfilProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Compras restauradas com sucesso.'),
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nenhuma compra anterior encontrada.'),
                            ),
                          );
                        }
                      },
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
