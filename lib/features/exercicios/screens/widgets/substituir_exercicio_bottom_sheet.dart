import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../data/substituicao_engine.dart';
import '../../providers/exercicios_provider.dart';

class SubstituirExercicioBottomSheet extends ConsumerWidget {
  const SubstituirExercicioBottomSheet({
    super.key,
    required this.alvo,
    required this.onEscolher,
    this.equipamentosAluno,
    this.onCriarNovo,
  });

  final Exercicio alvo;
  final Set<Equipamento>? equipamentosAluno;
  final ValueChanged<Exercicio> onEscolher;
  final VoidCallback? onCriarNovo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(exerciciosProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: asyncList.when(
          loading:
              () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (error, _) => SizedBox(
                height: 220,
                child: Center(child: Text('Nao foi possivel buscar opcoes.')),
              ),
          data: (todos) {
            final alternativas = SubstituicaoEngine().encontrarAlternativas(
              alvo: alvo,
              candidatos: todos,
              equipamentosAluno: equipamentosAluno,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Substituir exercicio', style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  alvo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: EagleTokens.inkMute,
                  ),
                ),
                const SizedBox(height: 16),
                if (alternativas.isEmpty)
                  const _EmptyState()
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: alternativas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = alternativas[index];
                        return _AlternativaTile(
                          item: item,
                          onTap: () {
                            Navigator.of(context).pop();
                            onEscolher(item.exercicio);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCriarNovo?.call();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Criar exercicio novo'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlternativaTile extends StatelessWidget {
  const _AlternativaTile({required this.item, required this.onTap});

  final AlternativaResultado item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exercicio = item.exercicio;
    final chips =
        [
          if (exercicio.padraoMovimento != null)
            TaxonomyLabels.padrao[exercicio.padraoMovimento!],
          if (exercicio.grupoMuscularPrimario != null)
            TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!],
          if (exercicio.dificuldade != null)
            TaxonomyLabels.dificuldade[exercicio.dificuldade!],
          if (exercicio.equipamentos.isNotEmpty)
            TaxonomyLabels.equipamento[exercicio.equipamentos.first],
        ].whereType<String>().toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EagleTokens.line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: EagleTokens.good.withValues(alpha: .12),
                child: Text(
                  '${item.score}',
                  style: const TextStyle(
                    color: EagleTokens.good,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chips.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EagleTokens.inkMute,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: EagleTokens.inkMute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EagleTokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EagleTokens.line),
      ),
      child: const Text(
        'Nenhuma alternativa boa encontrada. Crie uma opcao nova ou ajuste os filtros do aluno.',
      ),
    );
  }
}
