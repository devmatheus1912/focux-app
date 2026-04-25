import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../data/planos_repository.dart';

class EnterprisePromoScreen extends ConsumerStatefulWidget {
  const EnterprisePromoScreen({super.key});
  @override
  ConsumerState<EnterprisePromoScreen> createState() => _State();
}

class _State extends ConsumerState<EnterprisePromoScreen> {
  bool _iniciando = false;

  Future<void> _startTrial() async {
    setState(() => _iniciando = true);
    try {
      await PlanosRepository(ref.read(apiClientProvider)).startTrial();
      ref.invalidate(perfilProvider);
      final prefs = await SharedPreferences.getInstance();
      final personalId = ref.read(perfilProvider).value?.id;
      if (personalId != null) await prefs.setBool('promo_shown_$personalId', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trial Enterprise ativado! 5 dias gratis.')));
        context.go('/dashboard/personal');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally { if (mounted) setState(() => _iniciando = false); }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final personalId = ref.read(perfilProvider).value?.id;
    if (personalId != null) await prefs.setBool('promo_shown_$personalId', true);
    if (mounted) context.go('/dashboard/personal');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 5));
    final dateStr = '${trialEndDate.day.toString().padLeft(2, '0')}/${trialEndDate.month.toString().padLeft(2, '0')}/${trialEndDate.year}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B3E), Color(0xFF0A0F1E)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Spacer(),
              const Icon(Icons.fitness_center, color: Color(0xFF3B5FE2), size: 56),
              const SizedBox(height: 20),
              const Text('Transforme seu negócio.\nExperimente o Enterprise.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 32),
              ...[
                'Alunos ilimitados', 'IA completa + RAG',
                'White-label — sua marca, suas cores',
                'Landing page profissional', 'Domínio customizado',
              ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 15))),
                ]))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.card_giftcard, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 8),
                    const Text('5 dias grátis', style: TextStyle(color: Color(0xFFF59E0B),
                      fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Cancele antes de $dateStr — sem cobrança alguma.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Após: R\$149,90/mês', textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _iniciando ? null : _startTrial,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5FE2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _iniciando
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Experimentar 5 dias grátis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _dismiss,
                child: const Text('Agora não', style: TextStyle(color: Colors.white54, fontSize: 14))),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }
}
