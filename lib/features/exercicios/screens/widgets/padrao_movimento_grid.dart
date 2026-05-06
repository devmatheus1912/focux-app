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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: SegmentedButton<PadraoGridMode>(
            segments: const [
              ButtonSegment(
                value: PadraoGridMode.padrao,
                label: Text('Padrao'),
              ),
              ButtonSegment(value: PadraoGridMode.grupo, label: Text('Grupo')),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.55,
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
    return Material(
      color: primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text('$count exercicios'),
            ],
          ),
        ),
      ),
    );
  }
}
