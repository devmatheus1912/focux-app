import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';
import 'padrao_exercicios_bottom_sheet.dart';

enum PadraoGridMode { padrao, grupo }

class PadraoMovimentoGrid extends ConsumerStatefulWidget {
  const PadraoMovimentoGrid({super.key, required this.onAdicionar});

  final ValueChanged<Exercicio> onAdicionar;

  @override
  ConsumerState<PadraoMovimentoGrid> createState() =>
      _PadraoMovimentoGridState();
}

class _PadraoMovimentoGridState extends ConsumerState<PadraoMovimentoGrid> {
  PadraoGridMode _mode = PadraoGridMode.padrao;

  static const _padroes = [
    PadraoMovimento.pushHorizontal,
    PadraoMovimento.pushVertical,
    PadraoMovimento.pullHorizontal,
    PadraoMovimento.pullVertical,
    PadraoMovimento.squat,
    PadraoMovimento.hinge,
    PadraoMovimento.lunge,
    PadraoMovimento.coreAntiExtensao,
    PadraoMovimento.coreAntiRotacao,
    PadraoMovimento.cardioHiit,
  ];

  @override
  Widget build(BuildContext context) {
    final all = ref
        .watch(exerciciosProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <Exercicio>[]);
    final items =
        _mode == PadraoGridMode.padrao
            ? [
              for (final padrao in _padroes)
                _GridItem(
                  label: TaxonomyLabels.padrao[padrao] ?? padrao.name,
                  count: all.where((ex) => ex.padraoMovimento == padrao).length,
                  icon: Icons.account_tree_rounded,
                  onTap: () => _open(padrao: padrao),
                ),
            ]
            : [
              for (final grupo in GrupoMuscular.values)
                _GridItem(
                  label: TaxonomyLabels.grupo[grupo] ?? grupo.name,
                  count:
                      all
                          .where((ex) => ex.grupoMuscularPrimario == grupo)
                          .length,
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _open(grupo: grupo),
                ),
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CategoryIntro(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: SegmentedButton<PadraoGridMode>(
            segments: const [
              ButtonSegment(
                value: PadraoGridMode.padrao,
                label: Text('Movimento'),
              ),
              ButtonSegment(value: PadraoGridMode.grupo, label: Text('Grupo')),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (_, index) => items[index],
          ),
        ),
      ],
    );
  }

  void _open({PadraoMovimento? padrao, GrupoMuscular? grupo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => PadraoExerciciosBottomSheet(
            padrao: padrao,
            grupo: grupo,
            onAdicionar: widget.onAdicionar,
          ),
    );
  }
}

class _CategoryIntro extends StatelessWidget {
  const _CategoryIntro();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.manage_search_rounded, color: primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha por intenção',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Abra uma categoria e selecione o exercício certo para prescrever.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: primary, size: 19),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '$count exercícios',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
