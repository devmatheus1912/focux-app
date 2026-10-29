import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../utils/exercise_picker_filter.dart';

Future<void> showExercisePickerFilterSheet(
  BuildContext context, {
  required ExercisePickerFilter filter,
  required ValueChanged<ExercisePickerFilter> onChanged,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _ExercisePickerFilterSheet(
          initialFilter: filter,
          onChanged: onChanged,
        ),
  );
}

class _ExercisePickerFilterSheet extends StatefulWidget {
  const _ExercisePickerFilterSheet({
    required this.initialFilter,
    required this.onChanged,
  });

  final ExercisePickerFilter initialFilter;
  final ValueChanged<ExercisePickerFilter> onChanged;

  @override
  State<_ExercisePickerFilterSheet> createState() =>
      _ExercisePickerFilterSheetState();
}

class _ExercisePickerFilterSheetState extends State<_ExercisePickerFilterSheet> {
  late ExercisePickerFilter _filter;

  static final _espacos = [
    Espaco.academiaCompleta,
    Espaco.academiaBasica,
    Espaco.casaEquipada,
    Espaco.casaSemEquipo,
  ];

  static final _equipamentos = [
    Equipamento.barra,
    Equipamento.halter,
    Equipamento.maquina,
    Equipamento.pesoCorporal,
    Equipamento.polia,
    Equipamento.banda,
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  bool get _hasAdvanced =>
      _filter.espaco != null || _filter.equipamentos.isNotEmpty;

  String _espacoLabel(Espaco espaco) =>
      TaxonomyLabels.espaco[espaco] ??
      TaxonomyLabels.espacoShort[espaco] ??
      espaco.name;

  String _equipamentoLabel(Equipamento equipamento) =>
      TaxonomyLabels.equipamento[equipamento] ?? equipamento.name;

  void _apply(ExercisePickerFilter next) {
    setState(() => _filter = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final ativos =
        (_filter.espaco != null ? 1 : 0) + _filter.equipamentos.length;

    return FxSheetFrame(
      title: 'Filtros',
      subtitle: 'Escolha mais de um equipamento se quiser.',
      leading: Icon(Icons.tune_rounded, color: brand, size: 20),
      footer: Row(
        children: [
          if (_hasAdvanced) ...[
            FxTonalButton(
              label: 'Limpar',
              icon: Icons.close_rounded,
              onPressed: () {
                HapticFeedback.selectionClick();
                _apply(
                  _filter.copyWith(clearEspaco: true, clearEquipamento: true),
                );
              },
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FxLiquidPrimaryButton(
              label: ativos > 0 ? 'Aplicar ($ativos)' : 'Concluir',
              onPressed: () => FxHomeSheetChrome.dismissAndPop(context),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSettingsGroup(
            accent: primary,
            edgeToEdgeRows: true,
            caption: 'Onde o aluno treina',
            children: FxInsetPickerOption.list(
              accent: brand,
              items: [
                for (final espaco in _espacos)
                  FxInsetPickerOptionSpec(
                    label: _espacoLabel(espaco),
                    selected: _filter.espaco == espaco,
                    onTap: () {
                      _apply(
                        _filter.espaco == espaco
                            ? _filter.copyWith(clearEspaco: true)
                            : _filter.copyWith(espaco: espaco),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            accent: primary,
            edgeToEdgeRows: true,
            caption: 'Equipamento (um ou mais)',
            children: FxInsetPickerOption.list(
              accent: brand,
              items: [
                for (final equipamento in _equipamentos)
                  FxInsetPickerOptionSpec(
                    label: _equipamentoLabel(equipamento),
                    selected: _filter.equipamentos.contains(equipamento),
                    onTap: () {
                      final next = {..._filter.equipamentos};
                      if (!next.add(equipamento)) next.remove(equipamento);
                      _apply(_filter.copyWith(equipamentos: next));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
