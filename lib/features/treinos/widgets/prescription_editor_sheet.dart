import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../data/exercise_prescription_memory.dart';
import '../data/workout_builder_preset.dart';
import '../utils/workout_prescription_display.dart';

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

  String _previewLine(WorkoutBuilderPreset preset) {
    final series = widget.seriesCtrl.text.trim().isEmpty
        ? '${preset.series}'
        : widget.seriesCtrl.text.trim();
    final reps = widget.repCtrl.text.trim().isEmpty
        ? preset.repeticoes
        : widget.repCtrl.text.trim();
    final rest = widget.descansoCtrl.text.trim().isEmpty
        ? '${preset.descansoSegundos}'
        : widget.descansoCtrl.text.trim();
    return formatActivePrescriptionLine(
      presetLabel: preset.label,
      series: series,
      repeticoes: reps,
      descansoSegundos: rest,
      tipoSerie: _tipoSerie,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandPalette.softened(widget.primary);
    final mute = widget.isDark
        ? EagleTokens.darkInkMute
        : TokensStrip.textSecondary;
    final line = widget.isDark
        ? EagleTokens.darkLine
        : TokensStrip.borderDefault;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final selectedPreset = workoutBuilderPresetById(_presetId);
    final previewLine = _previewLine(selectedPreset);

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      expand: true,
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        10,
        FxSettingsLayout.pageInset,
        FxSettingsLayout.pageInset,
      ),
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
            leading: Icon(
              Icons.edit_note_rounded,
              color: brand,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
            ),
            child: Text(
              previewLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: activePrescriptionLineStyle(brand: brand),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboardInset + 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.lastPrescription != null) ...[
                    _RepeatPrescriptionTile(
                      memory: widget.lastPrescription!,
                      primary: widget.primary,
                      brand: brand,
                      isDark: widget.isDark,
                      line: line,
                      onApply: widget.onApplyLastPrescription,
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                  ],
                  FxSettingsGroup(
                    header: 'Objetivo',
                    accent: widget.primary,
                    footer: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FxSettingsLayout.groupPadH,
                      ),
                      child: Text(
                        selectedPreset.summary,
                        style: FxSettingsLayout.footer(color: mute),
                      ),
                    ),
                    children: [
                      AlunoSegmentedChoice(
                        options: [
                          for (final preset in workoutBuilderPresets)
                            (value: preset.id, label: preset.label),
                        ],
                        selected: _presetId,
                        isDark: widget.isDark,
                        onSelect: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _presetId = value);
                          widget.onPresetSelected(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Volume',
                    accent: widget.primary,
                    children: [
                      _PrescriptionInsetField(
                        controller: widget.seriesCtrl,
                        label: 'Séries',
                        icon: Icons.format_list_numbered_rounded,
                        iconColor: brand,
                        keyboardType: TextInputType.number,
                        line: line,
                      ),
                      _PrescriptionInsetField(
                        controller: widget.repCtrl,
                        label: 'Repetições',
                        icon: Icons.fitness_center_rounded,
                        iconColor: brand,
                        line: line,
                      ),
                      _PrescriptionInsetField(
                        controller: widget.descansoCtrl,
                        label: 'Descanso (s)',
                        icon: Icons.timer_outlined,
                        iconColor: brand,
                        keyboardType: TextInputType.number,
                        line: line,
                      ),
                      _PrescriptionInsetField(
                        controller: widget.cargaCtrl,
                        label: 'Carga (kg)',
                        icon: Icons.scale_rounded,
                        iconColor: brand,
                        hint: 'Opcional',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        line: line,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Execução',
                    accent: widget.primary,
                    footer: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FxSettingsLayout.groupPadH,
                      ),
                      child: Text(
                        'Dica: orientações curtas ajudam o aluno na execução.',
                        style: FxSettingsLayout.footer(color: mute),
                      ),
                    ),
                    children: [
                      AlunoChoiceSection(
                        label: 'Tipo de série',
                        isDark: widget.isDark,
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
                      if (_tipoSerie == 'SUPERSET') ...[
                        Divider(
                          height: 1,
                          thickness: FxSettingsLayout.dividerThickness,
                          color: line.withValues(alpha: widget.isDark ? 0.55 : 0.7),
                        ),
                        _PrescriptionInsetField(
                          controller: widget.grupoSupersetCtrl,
                          label: 'Grupo do superset',
                          icon: Icons.link_rounded,
                          iconColor: brand,
                          hint: 'Mesmo número em exercícios juntos',
                          keyboardType: TextInputType.number,
                          line: line,
                        ),
                      ],
                      if (_tipoSerie == 'DROPSET') ...[
                        Divider(
                          height: 1,
                          thickness: FxSettingsLayout.dividerThickness,
                          color: line.withValues(alpha: widget.isDark ? 0.55 : 0.7),
                        ),
                        _ModeHint(
                          icon: Icons.trending_down_rounded,
                          text:
                              'Drop set: registre reduções de carga nas observações.',
                          color: EagleTokens.warn,
                          isDark: widget.isDark,
                        ),
                      ],
                      Divider(
                        height: 1,
                        thickness: FxSettingsLayout.dividerThickness,
                        color: line.withValues(alpha: widget.isDark ? 0.55 : 0.7),
                      ),
                      _PrescriptionInsetField(
                        controller: widget.observacoesCtrl,
                        label: 'Observações',
                        icon: Icons.notes_rounded,
                        iconColor: brand,
                        hint: 'Orientações de execução',
                        line: line,
                        maxLines: 4,
                        minLines: 2,
                        showDivider: false,
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

/// Campo borderless dentro de [FxSettingsGroup] — paridade Perfil/editar perfil.
class _PrescriptionInsetField extends StatelessWidget {
  const _PrescriptionInsetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.line,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines = 1,
    this.showDivider = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color line;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int minLines;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            style: FxSettingsLayout.rowMetric(color: fxScreenInk(context)),
            decoration: FxInputDeco.insetGrouped(
              context,
              icon: icon,
              hint: hint ?? label,
              iconColor: iconColor,
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: line,
          ),
      ],
    );
  }
}

class _RepeatPrescriptionTile extends StatelessWidget {
  const _RepeatPrescriptionTile({
    required this.memory,
    required this.primary,
    required this.brand,
    required this.isDark,
    required this.line,
    required this.onApply,
  });

  final ExercisePrescriptionMemory memory;
  final Color primary;
  final Color brand;
  final bool isDark;
  final Color line;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        border: Border.all(color: line.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: primary, size: 20),
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
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Aplicar',
                style: FocuxHubTypography.body(color: primary).copyWith(
                  fontWeight: FontWeight.w800,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: FocuxHubTypography.bodyMuted(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
