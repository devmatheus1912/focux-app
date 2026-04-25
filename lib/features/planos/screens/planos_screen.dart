import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../data/planos_repository.dart';

class PlanosScreen extends ConsumerStatefulWidget {
  const PlanosScreen({super.key});
  @override
  ConsumerState<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends ConsumerState<PlanosScreen> {
  bool _iniciandoTrial = false;

  Future<void> _startTrial() async {
    setState(() => _iniciandoTrial = true);
    try {
      await PlanosRepository(ref.read(apiClientProvider)).startTrial();
      ref.invalidate(perfilProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trial Enterprise ativado! 5 dias gratis comecando agora.')));
        context.go('/dashboard/personal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ativar trial: $e')));
      }
    } finally {
      if (mounted) setState(() => _iniciandoTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perfilAsync = ref.watch(perfilProvider);
    final plano = perfilAsync.value?.plano.toUpperCase() ?? 'FREE';
    final trialUsed = perfilAsync.value?.trialUsed ?? false;
    final trialEndsAt = perfilAsync.value?.trialEndsAt;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Planos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Escolha o plano ideal', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Invista no seu negócio como personal trainer.',
              style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),

            // Trial banner if active
            if (plano == 'ENTERPRISE' && trialEndsAt != null && trialEndsAt.isAfter(DateTime.now())) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EagleTokens.good.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EagleTokens.good.withValues(alpha: 0.4))),
                child: Row(children: [
                  Icon(Icons.timer_outlined, color: EagleTokens.good, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Trial Enterprise ativo! Expira em ${trialEndsAt.day.toString().padLeft(2, '0')}/${trialEndsAt.month.toString().padLeft(2, '0')}/${trialEndsAt.year}.',
                    style: TextStyle(color: EagleTokens.good, fontWeight: FontWeight.w600))),
                ])),
            ],

            const SizedBox(height: 24),

            // FREE
            _PlanCard(
              name: 'FREE', price: 'Grátis', isCurrent: plano == 'FREE',
              isDark: isDark, accentColor: const Color(0xFF6B7280),
              features: const ['Até 5 alunos', 'Recursos básicos do app', 'Sem IA avançada', 'Sem landing page'],
              cta: null),

            const SizedBox(height: 16),

            // PREMIUM
            _PlanCard(
              name: 'PREMIUM', price: 'R\$79/mês', isCurrent: plano == 'PREMIUM',
              isDark: isDark, accentColor: const Color(0xFF3B5FE2),
              features: const ['Até 20 alunos', 'IA com cota (50 req/mês)', 'Landing page (marca Focux)', 'Sem white-label'],
              cta: plano != 'PREMIUM' ? ElevatedButton(
                onPressed: () => context.go('/assinatura'),
                child: const Text('Assinar Premium')) : null),

            const SizedBox(height: 16),

            // ENTERPRISE (highlighted with glow)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2)]),
              child: _PlanCard(
                name: 'ENTERPRISE', price: 'R\$149,90/mês', isCurrent: plano == 'ENTERPRISE',
                isDark: isDark, accentColor: EagleTokens.brand,
                features: const [
                  'Alunos ilimitados', 'IA ilimitada + RAG', 'White-label completo',
                  'Marca própria (cores, logo, slogan)', 'Domínio customizado',
                  'Depoimentos + Galeria + Vídeo', 'Remove "Powered by Focux"'],
                cta: plano != 'ENTERPRISE'
                    ? Column(children: [
                        if (!trialUsed) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: EagleTokens.good.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.card_giftcard, color: EagleTokens.good, size: 16),
                              const SizedBox(width: 6),
                              Text('5 dias grátis disponíveis!',
                                style: TextStyle(color: EagleTokens.good, fontWeight: FontWeight.w700, fontSize: 13)),
                            ])),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: FilledButton(
                            onPressed: _iniciandoTrial ? null : _startTrial,
                            style: FilledButton.styleFrom(backgroundColor: EagleTokens.brand,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: _iniciandoTrial
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Experimentar 5 dias grátis', style: TextStyle(fontWeight: FontWeight.w700)))),
                          const SizedBox(height: 6),
                          Text('Cancele antes do vencimento — sem cobrança.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),
                        ],
                        if (trialUsed) ...[
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: FilledButton(
                            onPressed: () => context.go('/assinatura'),
                            style: FilledButton.styleFrom(backgroundColor: EagleTokens.brand,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Assinar Enterprise', style: TextStyle(fontWeight: FontWeight.w700)))),
                        ],
                      ]) : null)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name, price;
  final bool isCurrent, isDark;
  final Color accentColor;
  final List<String> features;
  final Widget? cta;

  const _PlanCard({required this.name, required this.price, required this.isCurrent,
    required this.isDark, required this.accentColor, required this.features, this.cta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? accentColor : (isDark ? EagleTokens.darkLine : EagleTokens.line),
          width: isCurrent ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isCurrent ? accentColor : null))),
          if (isCurrent) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('Atual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor))),
        ]),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accentColor)),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(Icons.check_circle_outline, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
          ]))),
        if (cta != null) ...[const SizedBox(height: 16), cta!],
      ]),
    );
  }
}
