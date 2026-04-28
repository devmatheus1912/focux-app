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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVO ITEM',
                        style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adicionar Exercício',
                        style: TextStyle(fontSize: 28, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mute),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: exerciciosAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: primary)),
                error: (e, _) => Center(child: Text('Erro: $e', style: TextStyle(color: EagleTokens.bad))),
                data: (exercicios) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Exercicio>(
                              value: _selecionado,
                              decoration: InputDecoration(
                                labelText: 'Exercício',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              items: exercicios.map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.nome, style: TextStyle(color: ink)),
                                  )).toList(),
                              onChanged: (v) => setState(() => _selecionado = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 56, // Match Dropdown height
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: primary),
                              tooltip: 'Criar novo exercício',
                              onPressed: () async {
                                final criado = await context.push<bool>('/exercicios/novo');
                                if (criado == true) {
                                  ref.invalidate(exerciciosProvider);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seriesCtrl,
                              decoration: InputDecoration(
                                labelText: 'Séries',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: ink),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repCtrl,
                              decoration: InputDecoration(
                                labelText: 'Repetições',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              style: TextStyle(color: ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descansoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Descanso (segundos)',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: ink),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: EagleTokens.bad.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: EagleTokens.bad, fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Adicionar ao Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
