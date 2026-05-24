import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../providers/alunos_provider.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class AlunoEquipamentosScreen extends ConsumerStatefulWidget {
  const AlunoEquipamentosScreen({super.key, required this.alunoId});

  final int alunoId;

  @override
  ConsumerState<AlunoEquipamentosScreen> createState() =>
      _AlunoEquipamentosScreenState();
}

class _AlunoEquipamentosScreenState
    extends ConsumerState<AlunoEquipamentosScreen> {
  Set<Equipamento>? _selected;
  bool _saving = false;

  Future<void> _save() async {
    final selected = _selected ?? {};
    setState(() => _saving = true);
    try {
      await ref
          .read(alunoRepositoryProvider)
          .atualizarEquipamentos(widget.alunoId, selected);
      ref.invalidate(alunoProvider(widget.alunoId));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alunoAsync = ref.watch(alunoProvider(widget.alunoId));
    final selected = _selected;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Equipamentos do aluno',
        onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
        actions:
            _saving
                ? [
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: FxLoading(strokeWidth: 2),
                    ),
                  ),
                ]
                : [
                  IconButton(
                    tooltip: 'Salvar',
                    icon: const Icon(Icons.check_rounded),
                    onPressed: _save,
                  ),
                ],
      ),
      body: alunoAsync.when(
        loading: () => const FxLoading(),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          _selected ??= {...aluno.equipamentosDisponiveis};
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s3,
              TokensStrip.s4,
              TokensStrip.s6,
            ),
            children: [
              Text(aluno.nome, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                'Use isto para filtrar substituicoes inteligentes e evitar prescrever algo que o aluno nao consegue executar.',
              ),
              const SizedBox(height: TokensStrip.s4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final equipamento in Equipamento.values)
                    FilterChip(
                      label: Text(
                        TaxonomyLabels.equipamento[equipamento] ??
                            equipamento.name,
                      ),
                      selected: selected?.contains(equipamento) ?? false,
                      onSelected:
                          (value) => setState(() {
                            final next = {...(_selected ?? {})};
                            value
                                ? next.add(equipamento)
                                : next.remove(equipamento);
                            _selected = next;
                          }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selected = {}),
                icon: const Icon(Icons.all_inclusive_rounded),
                label: const Text('Sem restricao'),
              ),
            ],
          );
        },
      ),
    );
  }
}
