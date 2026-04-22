import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final int treinoId;

  const CheckinScreen({super.key, required this.treinoId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  ExecucaoTreino? _execucao;
  bool _loading = true;
  bool _concluindo = false;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final execucao = await ref.read(checkinRepositoryProvider).iniciar(widget.treinoId);
      setState(() { _execucao = execucao; _loading = false; });
      if (execucao.iniciadoEm != null) {
        final start = DateTime.parse(execucao.iniciadoEm!);
        _duration = DateTime.now().difference(start);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _duration = DateTime.now().difference(start);
          });
        });
      }
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        context.pop();
      }
    }
  }

  Future<void> _marcar(ExecucaoExercicio ee, int seriesFeitas) async {
    if (_execucao == null) return;
    try {
      final updated = await ref.read(checkinRepositoryProvider)
          .marcarExercicio(_execucao!.id!, ee.treinoExercicioId, seriesFeitas);
      setState(() {
        _execucao = ExecucaoTreino(
          id: _execucao!.id,
          treinoId: _execucao!.treinoId,
          treinoNome: _execucao!.treinoNome,
          status: _execucao!.status,
          iniciadoEm: _execucao!.iniciadoEm,
          concluidoEm: _execucao!.concluidoEm,
          exercicios: _execucao!.exercicios
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _concluir() async {
    if (_execucao == null) return;
    setState(() { _concluindo = true; });
    try {
      await ref.read(checkinRepositoryProvider).concluir(_execucao!.id!);
      ref.invalidate(historicoCheckinProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino concluído! Parabéns!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() { _concluindo = false; });
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final exercicios = _execucao?.exercicios ?? [];
    final concluidos = exercicios.where((e) => e.concluido).length;
    final progresso = exercicios.isEmpty ? 0.0 : concluidos / exercicios.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_execucao?.treinoNome ?? 'Treino em andamento'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progresso, color: EagleTokens.good),
        ),
      ),
      body: Column(
        children: [
          // Cronômetro central
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const Text('TEMPO DE TREINO', style: TextStyle(color: EagleTokens.inkMute, fontSize: 12, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 8),
                Text(
                  '$concluidos de ${exercicios.length} exercícios concluídos',
                  style: const TextStyle(color: EagleTokens.good, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          
          // Card Sugestão IA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EagleTokens.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EagleTokens.brand.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: EagleTokens.brand, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Sugestão IA ao vivo', style: TextStyle(color: EagleTokens.brand, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Baseado no seu último treino, tente aumentar 2kg no supino hoje.', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: exercicios.length,
              itemBuilder: (context, i) => _ExercicioCard(
                ee: exercicios[i],
                onMarcar: (series) => _marcar(exercicios[i], series),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _concluindo ? null : _concluir,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _concluindo
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('FINALIZAR TREINO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercicioCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final void Function(int series) onMarcar;

  const _ExercicioCard({required this.ee, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ee.concluido ? EagleTokens.good : Colors.transparent, width: 2),
      ),
      child: ExpansionTile(
        initiallyExpanded: !ee.concluido,
        shape: const Border(),
        leading: Icon(
          ee.concluido ? Icons.check_circle : Icons.fitness_center,
          color: ee.concluido ? EagleTokens.good : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          ee.exercicioNome,
          style: TextStyle(fontWeight: FontWeight.bold, decoration: ee.concluido ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text('${ee.series ?? "-"} séries × ${ee.repeticoes ?? "-"} reps', style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (ee.gifUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(ee.gifUrl!, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Séries concluídas:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: ee.seriesFeitas > 0 ? () => onMarcar(ee.seriesFeitas - 1) : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text('${ee.seriesFeitas}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => onMarcar(ee.seriesFeitas + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
