import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/enums.dart';
import '../../data/exercise_enum_api.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_page.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../../treinos/utils/exercise_picker_filter.dart';
import '../../providers/exercicio_picker_provider.dart';
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

  List<_GridItemData> _itemsForMode(PadraoGridMode mode, ExercicioPickerStats stats) {
    if (mode == PadraoGridMode.padrao) {
      return [
        for (final padrao in _padroes)
          if (exercisePickerStatCount(stats.porPadrao, padrao.name) > 0)
            _GridItemData(
              label: TaxonomyLabels.padrao[padrao] ?? padrao.name,
              count: exercisePickerStatCount(stats.porPadrao, padrao.name),
              icon: Icons.account_tree_outlined,
              onTap: () => _open(padrao: padrao),
            ),
      ]..sort((a, b) => b.count.compareTo(a.count));
    }
    return [
      for (final grupo in GrupoMuscular.values)
        if (exercisePickerStatCount(stats.porGrupo, grupo.name) > 0)
          _GridItemData(
            label: TaxonomyLabels.grupo[grupo] ?? grupo.name,
            count: exercisePickerStatCount(stats.porGrupo, grupo.name),
            icon: Icons.fitness_center_outlined,
            onTap: () => _open(grupo: grupo),
          ),
    ]..sort((a, b) => b.count.compareTo(a.count));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(exercicioPickerStatsProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;

    return statsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SkeletonList(count: 5),
          ),
      error:
          (_, __) => FxEmptyState(
            icon: 'wifi-off',
            title: 'Não carregamos as categorias',
            subtitle: 'Verifique a conexão e tente de novo.',
            action: FxEmptyAction(
              label: 'Tentar novamente',
              onTap: () => ref.invalidate(exercicioPickerStatsProvider),
            ),
          ),
      data: (stats) {
        final items = _itemsForMode(_mode, stats);
        final modeCaption =
            _mode == PadraoGridMode.padrao
                ? 'Padrões de movimento'
                : 'Grupos musculares';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxSettingsGroup(
              accent: primary,
              caption: 'Como explorar',
              children: [
                FxSettingsTile(
                  icon: Icons.account_tree_outlined,
                  accent: primary,
                  label: 'Por movimento',
                  subtitle: 'Empurrar, puxar, agachar, core…',
                  value: '',
                  highlight: _mode == PadraoGridMode.padrao,
                  onTap: () => setState(() => _mode = PadraoGridMode.padrao),
                ),
                FxSettingsTile(
                  icon: Icons.fitness_center_outlined,
                  accent: primary,
                  label: 'Por grupo muscular',
                  subtitle: 'Peito, costas, pernas, ombro…',
                  value: '',
                  highlight: _mode == PadraoGridMode.grupo,
                  showDivider: false,
                  onTap: () => setState(() => _mode = PadraoGridMode.grupo),
                ),
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            if (items.isEmpty)
              FxEmptyState(
                icon: 'search',
                title:
                    widget.pickerFilter.isActive
                        ? 'Nada com estes filtros'
                        : 'Sem categorias nesta visão',
                subtitle:
                    widget.pickerFilter.isActive
                        ? 'Limpe os filtros ou busque pelo nome na aba Buscar.'
                        : 'Use a aba Buscar ou abra a biblioteca completa.',
                action:
                    widget.pickerFilter.isActive && widget.onClearFilters != null
                        ? FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap: widget.onClearFilters!,
                        )
                        : null,
              )
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    FxSettingsGroup(
                      accent: primary,
                      caption: '$modeCaption · ${items.length}',
                      children: [
                        for (var i = 0; i < items.length; i++)
                          FxSettingsTile(
                            icon: items[i].icon,
                            accent: primary,
                            label: items[i].label,
                            subtitle: '${items[i].count} exercícios',
                            value: '${items[i].count}',
                            numeric: true,
                            showDivider: i < items.length - 1,
                            onTap: items[i].onTap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Toque em uma categoria para ver exercícios e prescrever.',
                        style: FocuxHubTypography.bodyMuted(
                          color: mute,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
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
