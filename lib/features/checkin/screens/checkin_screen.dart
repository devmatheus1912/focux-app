import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final execucao = await ref.read(checkinRepositoryProvider).iniciar(widget.treinoId);
      setState(() { _execucao = execucao; _loading = false; });
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
        title: Text(_execucao?.treinoNome ?? 'Treino'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progresso),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$concluidos / ${exercicios.length} exercícios concluídos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: _concluindo
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Concluir treino'),
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
      color: ee.concluido
          ? Colors.green.withValues(alpha: 0.08)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ee.concluido ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: ee.concluido ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ee.exercicioNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (ee.series != null || ee.repeticoes != null) ...[
              const SizedBox(height: 4),
              Text(
                '${ee.series != null ? "${ee.series} séries" : ""}${ee.series != null && ee.repeticoes != null ? " × " : ""}${ee.repeticoes ?? ""}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Séries feitas: ${ee.seriesFeitas}'),
                const Spacer(),
                if (!ee.concluido) ...[
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: ee.seriesFeitas > 0 ? () => onMarcar(ee.seriesFeitas - 1) : null,
                  ),
                  Text('${ee.seriesFeitas}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => onMarcar(ee.seriesFeitas + 1),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
