import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
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
          filter: filter,
          onChanged: onChanged,
        ),
  );
}

class _ExercisePickerFilterSheet extends StatelessWidget {
  const _ExercisePickerFilterSheet({
    required this.filter,
    required this.onChanged,
  });

  final ExercisePickerFilter filter;
  final ValueChanged<ExercisePickerFilter> onChanged;

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

  bool get _hasAdvanced =>
      filter.espaco != null || filter.equipamento != null;

  String _espacoLabel(Espaco espaco) =>
      TaxonomyLabels.espaco[espaco] ??
      TaxonomyLabels.espacoShort[espaco] ??
      espaco.name;

  String _equipamentoLabel(Equipamento equipamento) =>
      TaxonomyLabels.equipamento[equipamento] ?? equipamento.name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: 8),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Filtros',
            subtitle: 'Refina por espaço e equipamento.',
            leading: Icon(Icons.tune_rounded, color: brand, size: 20),
            trailing:
                _hasAdvanced
                    ? TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onChanged(
                          filter.copyWith(
                            clearEspaco: true,
                            clearEquipamento: true,
                          ),
                        );
                      },
                      child: Text(
                        'Limpar',
                        style: FxSettingsLayout.rowLabel(color: brand),
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxSettingsGroup(
                    accent: primary,
                    caption: 'Onde o aluno treina',
                    children: [
                      for (var i = 0; i < _espacos.length; i++)
                        _FilterPickerTile(
                          label: _espacoLabel(_espacos[i]),
                          selected: filter.espaco == _espacos[i],
                          accent: brand,
                          showDivider: i < _espacos.length - 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(
                              filter.espaco == _espacos[i]
                                  ? filter.copyWith(clearEspaco: true)
                                  : filter.copyWith(espaco: _espacos[i]),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    accent: primary,
                    caption: 'Equipamento principal',
                    children: [
                      for (var i = 0; i < _equipamentos.length; i++)
                        _FilterPickerTile(
                          label: _equipamentoLabel(_equipamentos[i]),
                          selected: filter.equipamento == _equipamentos[i],
                          accent: brand,
                          showDivider: i < _equipamentos.length - 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(
                              filter.equipamento == _equipamentos[i]
                                  ? filter.copyWith(clearEquipamento: true)
                                  : filter.copyWith(
                                    equipamento: _equipamentos[i],
                                  ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPickerTile extends StatelessWidget {
  const _FilterPickerTile({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = selected ? accent : chrome.ink;
    final line = chrome.line;

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, selecionado' : label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border:
                  showDivider
                      ? Border(
                        bottom: BorderSide(
                          color: line,
                          width: FxSettingsLayout.dividerThickness,
                        ),
                      )
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.rowLabel(color: ink),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_rounded,
                      color: accent,
                      size: FxSettingsLayout.iconSize,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
