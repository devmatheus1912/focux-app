import 'package:flutter/material.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_icon.dart';
import '../../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../models/exercicios_ui_filter.dart';
import '../../utils/exercicios_filter_display.dart';

Future<void> showExerciciosLibraryFiltersSheet(
  BuildContext context, {
  required ExerciciosUiFilter filter,
  required ValueChanged<ExerciciosUiFilter> onChanged,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _ExerciciosFilterSheet(
          isDark: isDark,
          filter: filter,
          onChanged: onChanged,
        ),
  );
}

class _ExerciciosFilterSheet extends StatefulWidget {
  const _ExerciciosFilterSheet({
    required this.isDark,
    required this.filter,
    required this.onChanged,
  });

  final bool isDark;
  final ExerciciosUiFilter filter;
  final ValueChanged<ExerciciosUiFilter> onChanged;

  @override
  State<_ExerciciosFilterSheet> createState() => _ExerciciosFilterSheetState();
}

class _ExerciciosFilterSheetState extends State<_ExerciciosFilterSheet> {
  late ExerciciosUiFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  void _emit(ExerciciosUiFilter next) {
    setState(() => _filter = next);
    widget.onChanged(next);
  }

  Future<void> _pick<T extends Enum>({
    required String title,
    required List<T> values,
    required Map<T, String> labels,
    required T? selected,
    required void Function(T value) onPick,
  }) async {
    final picked = await showFxInsetPickerSheet<T>(
      context,
      title: title,
      selected: selected,
      items: [
        for (final value in values)
          FxInsetPickerSheetItem(
            value: value,
            label: labels[value] ?? value.name,
          ),
      ],
    );
    if (picked == null) return;
    onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;
    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: widget.isDark),
          const SizedBox(height: 8),
          FxHomeSheetHeader(
            isDark: widget.isDark,
            title: exerciciosFiltrosHeader(),
            subtitle: exerciciosFilterSummary(_filter),
            leading: FxIcon(
              name: 'target',
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxSettingsGroup(
                    header: 'Taxonomia',
                    children: [
                      FxSettingsTile(
                        fxIcon: 'dumbbell',
                        label: 'Modalidade',
                        value: exerciciosEnumValue(
                          _filter.modalidade,
                          TaxonomyLabels.modalidade,
                          exerciciosModalidadeTodas(),
                        ),
                        highlight: _filter.modalidade != null,
                        onTap:
                            () => _pick<Modalidade>(
                              title: 'Modalidade',
                              values: Modalidade.values,
                              labels: TaxonomyLabels.modalidade,
                              selected: _filter.modalidade,
                              onPick:
                                  (v) => _emit(_filter.copyWith(modalidade: v)),
                            ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'target',
                        label: 'Grupo',
                        value: exerciciosEnumValue(
                          _filter.grupo,
                          TaxonomyLabels.grupo,
                          exerciciosGrupoTodos(),
                        ),
                        highlight: _filter.grupo != null,
                        onTap:
                            () => _pick<GrupoMuscular>(
                              title: 'Grupo muscular',
                              values: GrupoMuscular.values,
                              labels: TaxonomyLabels.grupo,
                              selected: _filter.grupo,
                              onPick: (v) => _emit(_filter.copyWith(grupo: v)),
                            ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'home',
                        label: 'Equipamento',
                        value: exerciciosEnumValue(
                          _filter.equipamento,
                          TaxonomyLabels.equipamento,
                          exerciciosEquipamentoTodos(),
                        ),
                        highlight: _filter.equipamento != null,
                        onTap:
                            () => _pick<Equipamento>(
                              title: 'Equipamento',
                              values: Equipamento.values,
                              labels: TaxonomyLabels.equipamento,
                              selected: _filter.equipamento,
                              onPick:
                                  (v) => _emit(_filter.copyWith(equipamento: v)),
                            ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'trend',
                        label: 'Nível',
                        value: exerciciosEnumValue(
                          _filter.dificuldade,
                          TaxonomyLabels.dificuldade,
                          exerciciosNivelTodos(),
                        ),
                        highlight: _filter.dificuldade != null,
                        showDivider: false,
                        onTap:
                            () => _pick<Dificuldade>(
                              title: 'Nível',
                              values: Dificuldade.values,
                              labels: TaxonomyLabels.dificuldade,
                              selected: _filter.dificuldade,
                              onPick:
                                  (v) =>
                                      _emit(_filter.copyWith(dificuldade: v)),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Biblioteca',
                    children: [
                      FxSettingsTile(
                        fxIcon: 'star',
                        label: exerciciosFavoritosLabel(),
                        value: _filter.favoritos ? 'Ativo' : '',
                        highlight: _filter.favoritos,
                        accessory: Switch.adaptive(
                          value: _filter.favoritos,
                          onChanged:
                              (v) => _emit(_filter.copyWith(favoritos: v)),
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'circle-check',
                        label: exerciciosComVideoLabel(),
                        value: _filter.comVideo ? 'Ativo' : '',
                        highlight: _filter.comVideo,
                        accessory: Switch.adaptive(
                          value: _filter.comVideo,
                          onChanged:
                              (v) => _emit(
                                _filter.copyWith(
                                  comVideo: v,
                                  semVideo: v ? false : _filter.semVideo,
                                ),
                              ),
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'x',
                        label: exerciciosSemVideoLabel(),
                        value: _filter.semVideo ? 'Ativo' : '',
                        highlight: _filter.semVideo,
                        showDivider: false,
                        accessory: Switch.adaptive(
                          value: _filter.semVideo,
                          onChanged:
                              (v) => _emit(
                                _filter.copyWith(
                                  semVideo: v,
                                  comVideo: v ? false : _filter.comVideo,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (_filter.hasFacet) ...[
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      children: [
                        FxSettingsTile(
                          fxIcon: 'x',
                          label: exerciciosLimparFiltros(),
                          value: '',
                          showDivider: false,
                          onTap:
                              () => _emit(
                                ExerciciosUiFilter(query: _filter.query),
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
