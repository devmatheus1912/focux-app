import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../data/exercise_prescription_memory.dart';
import '../data/workout_builder_preset.dart';

Future<void> showPrescriptionEditorSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required Color ink,
  required String presetId,
  required String tipoSerie,
  required bool globalPresetMode,
  required ExercisePrescriptionMemory? lastPrescription,
  required TextEditingController seriesCtrl,
  required TextEditingController repCtrl,
  required TextEditingController descansoCtrl,
  required TextEditingController cargaCtrl,
  required TextEditingController observacoesCtrl,
  required TextEditingController grupoSupersetCtrl,
  required ValueChanged<String> onPresetSelected,
  required ValueChanged<String> onTipoSerieChanged,
  required VoidCallback onApplyLastPrescription,
}) {
  HapticFeedback.selectionClick();
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => PrescriptionEditorSheet(
          isDark: isDark,
          primary: primary,
          ink: ink,
          presetId: presetId,
          tipoSerie: tipoSerie,
          globalPresetMode: globalPresetMode,
          lastPrescription: lastPrescription,
          seriesCtrl: seriesCtrl,
          repCtrl: repCtrl,
          descansoCtrl: descansoCtrl,
          cargaCtrl: cargaCtrl,
          observacoesCtrl: observacoesCtrl,
          grupoSupersetCtrl: grupoSupersetCtrl,
          onPresetSelected: onPresetSelected,
          onTipoSerieChanged: onTipoSerieChanged,
          onApplyLastPrescription: onApplyLastPrescription,
        ),
  );
}

class PrescriptionEditorSheet extends StatefulWidget {
  const PrescriptionEditorSheet({
    super.key,
    required this.isDark,
    required this.primary,
    required this.ink,
    required this.presetId,
    required this.tipoSerie,
    required this.globalPresetMode,
    required this.lastPrescription,
    required this.seriesCtrl,
    required this.repCtrl,
    required this.descansoCtrl,
    required this.cargaCtrl,
    required this.observacoesCtrl,
    required this.grupoSupersetCtrl,
    required this.onPresetSelected,
    required this.onTipoSerieChanged,
    required this.onApplyLastPrescription,
  });

  final bool isDark;
  final Color primary;
  final Color ink;
  final String presetId;
  final String tipoSerie;
  final bool globalPresetMode;
  final ExercisePrescriptionMemory? lastPrescription;
  final TextEditingController seriesCtrl;
  final TextEditingController repCtrl;
  final TextEditingController descansoCtrl;
  final TextEditingController cargaCtrl;
  final TextEditingController observacoesCtrl;
  final TextEditingController grupoSupersetCtrl;
  final ValueChanged<String> onPresetSelected;
  final ValueChanged<String> onTipoSerieChanged;
  final VoidCallback onApplyLastPrescription;

  @override
  State<PrescriptionEditorSheet> createState() => _PrescriptionEditorSheetState();
}

class _PrescriptionEditorSheetState extends State<PrescriptionEditorSheet> {
  late final Listenable _fieldsListenable;
  late String _presetId;
  late String _tipoSerie;

  @override
  void initState() {
    super.initState();
    _presetId = widget.presetId;
    _tipoSerie = widget.tipoSerie;
    _fieldsListenable = Listenable.merge([
      widget.seriesCtrl,
      widget.repCtrl,
      widget.descansoCtrl,
      widget.cargaCtrl,
    ]);
    _fieldsListenable.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fieldsListenable.removeListener(_onFieldsChanged);
    super.dispose();
  }

  String get _previewLabel {
    final preset = workoutBuilderPresetById(_presetId);
    final series = widget.seriesCtrl.text.trim().isEmpty
        ? '${preset.series}'
        : widget.seriesCtrl.text.trim();
    final reps = widget.repCtrl.text.trim().isEmpty
        ? preset.repeticoes
        : widget.repCtrl.text.trim();
    final rest = widget.descansoCtrl.text.trim().isEmpty
        ? '${preset.descansoSegundos}'
        : widget.descansoCtrl.text.trim();
    return '${preset.label} · $series×$reps · ${rest}s';
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandPalette.softened(widget.primary);
    final mute = widget.isDark
        ? EagleTokens.darkInkMute
        : TokensStrip.textSecondary;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    final fieldStyle = FocuxHubTypography.body(color: widget.ink).copyWith(
      fontWeight: FontWeight.w700,
    );
    final selectedPreset = workoutBuilderPresetById(_presetId);

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      expand: true,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: widget.isDark),
          const SizedBox(height: 8),
          FxHomeSheetHeader(
            isDark: widget.isDark,
            title:
                widget.globalPresetMode
                    ? 'Prescrição padrão'
                    : 'Prescrição do exercício',
            subtitle:
                widget.globalPresetMode
                    ? 'Vale para buscar, explorar e adições rápidas.'
                    : 'Ajuste séries, carga e descanso antes de salvar.',
            leading: Icon(Icons.edit_note_rounded, color: brand, size: 20),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brand.withValues(alpha: widget.isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _previewLabel,
                style: FocuxHubTypography.bodyMuted(
                  color: brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.lastPrescription != null) ...[
                    _RepeatPrescriptionTile(
                      memory: widget.lastPrescription!,
                      primary: widget.primary,
                      isDark: widget.isDark,
                      onApply: widget.onApplyLastPrescription,
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                  ],
                  FxSettingsGroup(
                    accent: widget.primary,
                    caption: selectedPreset.summary,
                    children: [
                      for (var i = 0; i < workoutBuilderPresets.length; i++)
                        _PickerRow(
                          label: workoutBuilderPresets[i].label,
                          selected: workoutBuilderPresets[i].id == _presetId,
                          accent: brand,
                          showDivider: i < workoutBuilderPresets.length - 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _presetId = workoutBuilderPresets[i].id);
                            widget.onPresetSelected(workoutBuilderPresets[i].id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    accent: widget.primary,
                    caption: 'Séries, repetições e descanso',
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: widget.seriesCtrl,
                                    decoration: FxInputDeco.build(
                                      context,
                                      'Séries',
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: fieldStyle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: widget.repCtrl,
                                    decoration: FxInputDeco.build(
                                      context,
                                      'Repetições',
                                    ),
                                    style: fieldStyle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: widget.descansoCtrl,
                                    decoration: FxInputDeco.build(
                                      context,
                                      'Descanso (s)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: fieldStyle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: widget.cargaCtrl,
                                    decoration: FxInputDeco.build(
                                      context,
                                      'Carga (kg)',
                                    ).copyWith(helperText: 'Opcional'),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: fieldStyle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  Text(
                    'Tipo de série',
                    style: FxSettingsLayout.sectionHeader(color: mute),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: fxListCardDecoration(
                      context,
                      accent: widget.primary,
                      radius: FxSettingsLayout.groupRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AlunoSegmentedChoice(
                        options: const [
                          (value: 'NORMAL', label: 'Normal'),
                          (value: 'SUPERSET', label: 'Superset'),
                          (value: 'DROPSET', label: 'Drop set'),
                        ],
                        selected: _tipoSerie,
                        isDark: widget.isDark,
                        onSelect: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _tipoSerie = value);
                          widget.onTipoSerieChanged(value);
                        },
                      ),
                    ),
                  ),
                  if (_tipoSerie == 'SUPERSET') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: widget.grupoSupersetCtrl,
                      decoration: FxInputDeco.build(
                        context,
                        'Grupo do superset',
                      ).copyWith(
                        helperText:
                            'Mesmo número em exercícios que ficam juntos.',
                      ),
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                    ),
                  ],
                  if (_tipoSerie == 'DROPSET') ...[
                    const SizedBox(height: 10),
                    _ModeHint(
                      icon: Icons.trending_down_rounded,
                      text:
                          'Drop set: registre reduções de carga nas observações.',
                      color: EagleTokens.warn,
                      isDark: widget.isDark,
                    ),
                  ],
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  TextFormField(
                    controller: widget.observacoesCtrl,
                    decoration: FxInputDeco.build(
                      context,
                      'Observações de execução',
                    ),
                    minLines: 2,
                    maxLines: 4,
                    style: fieldStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dica: ${selectedPreset.observacoes}',
                    style: FxSettingsLayout.footer(color: mute),
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

class _PickerRow extends StatelessWidget {
  const _PickerRow({
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

    return InkWell(
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
                    style: FxSettingsLayout.rowLabel(color: ink).copyWith(
                      fontWeight: selected ? FontWeight.w800 : null,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatPrescriptionTile extends StatelessWidget {
  const _RepeatPrescriptionTile({
    required this.memory,
    required this.primary,
    required this.isDark,
    required this.onApply,
  });

  final ExercisePrescriptionMemory memory;
  final Color primary;
  final bool isDark;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return DecoratedBox(
      decoration: fxListCardDecoration(context, accent: primary),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Repetir última (${memory.summary})',
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onApply,
              child: Text(
                'Aplicar',
                style: FocuxHubTypography.body(color: primary).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: FocuxHubTypography.bodyMuted(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
