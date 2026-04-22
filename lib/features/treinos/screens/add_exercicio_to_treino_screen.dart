import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../providers/treinos_provider.dart';

class AddExercicioToTreinoScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const AddExercicioToTreinoScreen({super.key, required this.treinoId});

  @override
  ConsumerState<AddExercicioToTreinoScreen> createState() =>
      _AddExercicioToTreinoScreenState();
}

class _AddExercicioToTreinoScreenState
    extends ConsumerState<AddExercicioToTreinoScreen> {
  Exercicio? _selecionado;
  final _seriesCtrl = TextEditingController(text: '3');
  final _repCtrl = TextEditingController(text: '10-12');
  final _descansoCtrl = TextEditingController(text: '60');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selecionado == null) {
      setState(() { _error = 'Selecione um exercício.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(treinoRepositoryProvider).adicionarExercicio(
        widget.treinoId,
        _selecionado!.id,
        series: int.tryParse(_seriesCtrl.text) ?? 3,
        repeticoes: _repCtrl.text,
        descanso: int.tryParse(_descansoCtrl.text) ?? 60,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao adicionar exercício.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Exercício')),
      body: exerciciosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (exercicios) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Exercicio>(
                value: _selecionado,
                decoration: const InputDecoration(labelText: 'Exercício'),
                items: exercicios.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.nome),
                    )).toList(),
                onChanged: (v) => setState(() => _selecionado = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seriesCtrl,
                      decoration: const InputDecoration(labelText: 'Séries'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _repCtrl,
                      decoration: const InputDecoration(labelText: 'Repetições'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _descansoCtrl,
                      decoration: const InputDecoration(labelText: 'Descanso (s)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: EagleTokens.bad)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
