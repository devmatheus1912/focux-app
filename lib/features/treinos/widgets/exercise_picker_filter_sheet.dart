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
      _filter.espaco != null || _filter.equipamento != null;

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
                        _apply(
                          _filter.copyWith(
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
              padding: const EdgeInsets.only(bottom: 8),
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
                          selected: _filter.espaco == _espacos[i],
                          accent: brand,
                          showDivider: i < _espacos.length - 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _apply(
                              _filter.espaco == _espacos[i]
                                  ? _filter.copyWith(clearEspaco: true)
                                  : _filter.copyWith(espaco: _espacos[i]),
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
                          selected: _filter.equipamento == _equipamentos[i],
                          accent: brand,
                          showDivider: i < _equipamentos.length - 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _apply(
                              _filter.equipamento == _equipamentos[i]
                                  ? _filter.copyWith(clearEquipamento: true)
                                  : _filter.copyWith(
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
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: TokensStrip.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.rowLabel(
                        color: ink,
                      ).copyWith(fontWeight: selected ? FontWeight.w800 : null),
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
