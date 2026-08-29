import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
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

  String _espacoLabel(Espaco espaco) =>
      TaxonomyLabels.espacoShort[espaco] ??
      TaxonomyLabels.espaco[espaco] ??
      espaco.name;

  String _equipamentoLabel(Equipamento equipamento) =>
      TaxonomyLabels.equipamento[equipamento] ?? equipamento.name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Filtros',
            subtitle: 'Espaço e equipamento na biblioteca inteira.',
            leading: Icon(Icons.tune_rounded, color: primary, size: 18),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.groupPadH,
                0,
                FxSettingsLayout.groupPadH,
                FxSettingsLayout.footerAfterGroup,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Espaço',
                    style: FxSettingsLayout.sectionHeader(color: mute),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final espaco in _espacos)
                        _FilterOptionChip(
                          label: _espacoLabel(espaco),
                          selected: filter.espaco == espaco,
                          primary: primary,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(
                              filter.espaco == espaco
                                  ? filter.copyWith(clearEspaco: true)
                                  : filter.copyWith(espaco: espaco),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  Text(
                    'Equipamento',
                    style: FxSettingsLayout.sectionHeader(color: mute),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final equipamento in _equipamentos)
                        _FilterOptionChip(
                          label: _equipamentoLabel(equipamento),
                          selected: filter.equipamento == equipamento,
                          primary: primary,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(
                              filter.equipamento == equipamento
                                  ? filter.copyWith(clearEquipamento: true)
                                  : filter.copyWith(equipamento: equipamento),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            filter.espaco == null && filter.equipamento == null
                                ? null
                                : () {
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
                          style: FocuxHubTypography.bodyMuted(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Pronto'),
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

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primary : line.withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              label,
              style: FocuxHubTypography.bodyMuted(
                color: selected ? primary : ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
