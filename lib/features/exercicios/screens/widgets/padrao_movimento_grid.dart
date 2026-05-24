import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../../treinos/utils/exercise_picker_filter.dart';
import '../../providers/exercicios_provider.dart';
import '../../../../core/widgets/fx_bottom_sheet.dart';
import 'padrao_exercicios_bottom_sheet.dart';

enum PadraoGridMode { padrao, grupo }

class PadraoMovimentoGrid extends ConsumerStatefulWidget {
  const PadraoMovimentoGrid({
    super.key,
    required this.onAdicionar,
    this.alreadyInTreinoIds = const {},
    this.pickerFilter = const ExercisePickerFilter(),
    this.onClearFilters,
  });

  final ValueChanged<Exercicio> onAdicionar;
  final Set<int> alreadyInTreinoIds;
  final ExercisePickerFilter pickerFilter;
  final VoidCallback? onClearFilters;

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

  List<_GridItemData> _itemsForMode(List<Exercicio> all) {
    final candidates =
        _mode == PadraoGridMode.padrao
            ? [
              for (final padrao in _padroes)
                _GridItemData(
                  label: TaxonomyLabels.padrao[padrao] ?? padrao.name,
                  count:
                      all.where((ex) => ex.padraoMovimento == padrao).length,
                  icon: Icons.account_tree_rounded,
                  onTap: () => _open(padrao: padrao),
                ),
            ]
            : [
              for (final grupo in GrupoMuscular.values)
                _GridItemData(
                  label: TaxonomyLabels.grupo[grupo] ?? grupo.name,
                  count:
                      all
                          .where((ex) => ex.grupoMuscularPrimario == grupo)
                          .length,
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _open(grupo: grupo),
                ),
            ];

    return candidates.where((item) => item.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref
        .watch(exerciciosProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <Exercicio>[]);
    final filtered = applyExercisePickerFilter(all, widget.pickerFilter);
    final items = _itemsForMode(filtered);
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;

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
          child:
              items.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_off_rounded,
                            color: mute.withValues(alpha: 0.7),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.pickerFilter.isActive
                                ? 'Nenhuma categoria combina com os filtros ativos.'
                                : 'Nenhuma categoria com exercícios disponíveis nesta visão.',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              color: mute,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          if (widget.pickerFilter.isActive &&
                              widget.onClearFilters != null) ...[
                            const SizedBox(height: 14),
                            FilledButton.tonal(
                              onPressed: widget.onClearFilters,
                              child: const Text('Limpar filtros'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: items.length,
                    itemBuilder:
                        (_, index) => _GridItem(
                          label: items[index].label,
                          count: items[index].count,
                          icon: items[index].icon,
                          onTap: items[index].onTap,
                        ),
                  ),
        ),
      ],
    );
  }

  void _open({PadraoMovimento? padrao, GrupoMuscular? grupo}) {
    showFxBottomSheet(
      context: context,
      builder:
          (_) => PadraoExerciciosBottomSheet(
            padrao: padrao,
            grupo: grupo,
            alreadyInTreinoIds: widget.alreadyInTreinoIds,
            pickerFilter: widget.pickerFilter,
            onAdicionar: widget.onAdicionar,
          ),
    );
  }
}

class _GridItemData {
  const _GridItemData({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
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
                Text(
                  'Escolha por intenção',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Abra uma categoria e selecione o exercício certo para prescrever.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
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
                style: AppTypography.inter(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '$count exercícios',
                style: AppTypography.inter(
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
