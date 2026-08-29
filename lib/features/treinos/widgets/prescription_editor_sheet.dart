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
import '../utils/prescription_volume_stepper.dart';
import '../utils/workout_prescription_display.dart';

/// Largura fixa do trailing — alinha steppers, campos e botão +.
const _prescriptionTrailingWidth = 128.0;

const _prescriptionLeadingWidth =
    FxSettingsLayout.iconSize + FxSettingsLayout.iconGap;

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
  bool _showCarga = false;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _presetId = widget.presetId;
    _tipoSerie = widget.tipoSerie;
    _showCarga = widget.cargaCtrl.text.trim().isNotEmpty;
    _showNotes = widget.observacoesCtrl.text.trim().isNotEmpty;
    _fieldsListenable = Listenable.merge([
      widget.seriesCtrl,
      widget.repCtrl,
      widget.descansoCtrl,
      widget.cargaCtrl,
      widget.observacoesCtrl,
    ]);
    _fieldsListenable.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.cargaCtrl.text.trim().isNotEmpty) _showCarga = true;
      if (widget.observacoesCtrl.text.trim().isNotEmpty) _showNotes = true;
    });
  }

  @override
  void dispose() {
    _fieldsListenable.removeListener(_onFieldsChanged);
    super.dispose();
  }

  WorkoutBuilderPreset get _selectedPreset => workoutBuilderPresetById(_presetId);

  String _previewLine() {
    final preset = _selectedPreset;
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

  void _setSeries(int value) {
    widget.seriesCtrl.text = '$value';
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _setRest(int value) {
    widget.descansoCtrl.text = '$value';
    HapticFeedback.selectionClick();
    setState(() {});
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
    final ink = fxScreenInk(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final selectedPreset = _selectedPreset;
    final seriesValue = parsePrescriptionInt(
      widget.seriesCtrl.text,
      fallback: selectedPreset.series,
    );
    final restValue = parsePrescriptionInt(
      widget.descansoCtrl.text,
      fallback: selectedPreset.descansoSegundos,
    );

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      expand: false,
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        12,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardInset + 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: widget.isDark),
            const SizedBox(height: 6),
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: _prescriptionLeadingWidth),
              child: Text(
                _previewLine(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: activePrescriptionLineStyle(brand: brand),
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            if (widget.lastPrescription != null) ...[
              _RepeatPrescriptionTile(
                memory: widget.lastPrescription!,
                primary: widget.primary,
                brand: brand,
                isDark: widget.isDark,
                line: line,
                onApply: widget.onApplyLastPrescription,
              ),
              const SizedBox(height: TokensStrip.s3),
            ],
            FxSettingsGroup(
              header: 'Ajustes rápidos',
              accent: widget.primary,
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
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Text(
                    selectedPreset.summary,
                    style: FxSettingsLayout.footer(color: mute),
                  ),
                ),
                _PrescriptionStepperRow(
                  label: 'Séries',
                  icon: Icons.format_list_numbered_rounded,
                  iconColor: brand,
                  value: '$seriesValue',
                  line: line,
                  ink: ink,
                  mute: mute,
                  onDecrement:
                      () => _setSeries(
                        adjustPrescriptionSeries(seriesValue, -1),
                      ),
                  onIncrement:
                      () => _setSeries(
                        adjustPrescriptionSeries(seriesValue, 1),
                      ),
                ),
                _PrescriptionRepsRow(
                  label: 'Repetições',
                  icon: Icons.fitness_center_rounded,
                  iconColor: brand,
                  controller: widget.repCtrl,
                  hint: selectedPreset.repeticoes,
                  line: line,
                  ink: ink,
                  mute: mute,
                  brand: brand,
                  shortcuts: workoutBuilderRepShortcuts(_presetId),
                  onShortcut: (value) {
                    widget.repCtrl.text = value;
                    HapticFeedback.selectionClick();
                    setState(() {});
                  },
                ),
                _PrescriptionStepperRow(
                  label: 'Descanso',
                  icon: Icons.timer_outlined,
                  iconColor: brand,
                  value: '${restValue}s',
                  line: line,
                  ink: ink,
                  mute: mute,
                  onDecrement:
                      () => _setRest(
                        adjustPrescriptionRestSeconds(restValue, -15),
                      ),
                  onIncrement:
                      () => _setRest(
                        adjustPrescriptionRestSeconds(restValue, 15),
                      ),
                ),
                if (_showCarga)
                  _PrescriptionValueRow(
                    label: 'Carga (kg)',
                    icon: Icons.scale_rounded,
                    iconColor: brand,
                    controller: widget.cargaCtrl,
                    hint: 'Opcional',
                    line: line,
                    ink: ink,
                    mute: mute,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  )
                else
                  _PrescriptionExpandRow(
                    label: 'Adicionar carga (kg)',
                    icon: Icons.scale_rounded,
                    iconColor: brand,
                    line: line,
                    mute: mute,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showCarga = true);
                    },
                  ),
                Divider(
                  height: 1,
                  thickness: FxSettingsLayout.dividerThickness,
                  color: line,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    'Tipo de série',
                    style: FxSettingsLayout.sectionHeader(color: mute),
                  ),
                ),
                AlunoSegmentedChoice(
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
                if (_tipoSerie == 'SUPERSET')
                  _PrescriptionValueRow(
                    label: 'Grupo superset',
                    icon: Icons.link_rounded,
                    iconColor: brand,
                    controller: widget.grupoSupersetCtrl,
                    hint: 'Nº em comum',
                    line: line,
                    ink: ink,
                    mute: mute,
                    keyboardType: TextInputType.number,
                  ),
                if (_tipoSerie == 'DROPSET')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Registre reduções de carga nas observações.',
                      style: FxSettingsLayout.footer(color: mute),
                    ),
                  ),
                if (_showNotes)
                  _PrescriptionNotesField(
                    controller: widget.observacoesCtrl,
                    iconColor: brand,
                    ink: ink,
                  )
                else
                  _PrescriptionExpandRow(
                    label: 'Adicionar observações',
                    icon: Icons.notes_rounded,
                    iconColor: brand,
                    line: line,
                    mute: mute,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showNotes = true);
                    },
                    showDivider: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionStepperRow extends StatelessWidget {
  const _PrescriptionStepperRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.line,
    required this.ink,
    required this.mute,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color line;
  final Color ink;
  final Color mute;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
            const SizedBox(width: FxSettingsLayout.iconGap),
            Expanded(
              child: Text(
                label,
                style: FxSettingsLayout.rowLabel(color: ink),
              ),
            ),
            SizedBox(
              width: _prescriptionTrailingWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: onDecrement,
                    mute: mute,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: FxSettingsLayout.rowLabel(color: ink).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrement,
                    mute: mute,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.mute,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: mute),
        ),
      ),
    );
  }
}

class _PrescriptionValueRow extends StatelessWidget {
  const _PrescriptionValueRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    required this.line,
    required this.ink,
    required this.mute,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String hint;
  final Color line;
  final Color ink;
  final Color mute;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
            const SizedBox(width: FxSettingsLayout.iconGap),
            Expanded(
              child: Text(
                label,
                style: FxSettingsLayout.rowLabel(color: ink),
              ),
            ),
            SizedBox(
              width: _prescriptionTrailingWidth,
              child: Semantics(
                label: label,
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  style: FxSettingsLayout.rowValue(color: ink).copyWith(
                    fontSize: TokensStrip.fontBody,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: FxSettingsLayout.rowValue(color: mute),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionRepsRow extends StatelessWidget {
  const _PrescriptionRepsRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    required this.line,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.shortcuts,
    required this.onShortcut,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String hint;
  final Color line;
  final Color ink;
  final Color mute;
  final Color brand;
  final List<String> shortcuts;
  final ValueChanged<String> onShortcut;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    return _PrescriptionRowDivider(
      line: line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
                const SizedBox(width: FxSettingsLayout.iconGap),
                Expanded(
                  child: Text(
                    label,
                    style: FxSettingsLayout.rowLabel(color: ink),
                  ),
                ),
                SizedBox(
                  width: _prescriptionTrailingWidth,
                  child: Semantics(
                    label: label,
                    child: TextFormField(
                      controller: controller,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      style: FxSettingsLayout.rowValue(color: ink).copyWith(
                        fontSize: TokensStrip.fontBody,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: FxSettingsLayout.rowValue(color: mute),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _prescriptionLeadingWidth, bottom: 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final option in shortcuts)
                  _RepChip(
                    label: option,
                    selected: current == option,
                    brand: brand,
                    line: line,
                    mute: mute,
                    onTap: () => onShortcut(option),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepChip extends StatelessWidget {
  const _RepChip({
    required this.label,
    required this.selected,
    required this.brand,
    required this.line,
    required this.mute,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color brand;
  final Color line;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Repetições $label',
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  selected
                      ? brand.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    selected
                        ? brand.withValues(alpha: 0.35)
                        : line.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                label,
                style: FxSettingsLayout.rowValue(color: mute).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? brand : mute,
                  fontSize: TokensStrip.fontBodySm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionRowDivider extends StatelessWidget {
  const _PrescriptionRowDivider({
    required this.line,
    required this.child,
    this.showDivider = true,
  });

  final Color line;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
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

class _PrescriptionExpandRow extends StatelessWidget {
  const _PrescriptionExpandRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.line,
    required this.mute,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color line;
  final Color mute;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      showDivider: showDivider,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
                const SizedBox(width: FxSettingsLayout.iconGap),
                Expanded(
                  child: Text(
                    label,
                    style: FxSettingsLayout.rowLabel(
                      color: fxScreenInk(context),
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: _prescriptionTrailingWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.add_rounded, size: 20, color: mute),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionNotesField extends StatelessWidget {
  const _PrescriptionNotesField({
    required this.controller,
    required this.iconColor,
    required this.ink,
  });

  final TextEditingController controller;
  final Color iconColor;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        label: 'Observações de execução',
        child: TextFormField(
          controller: controller,
          minLines: 2,
          maxLines: 3,
          style: FocuxHubTypography.body(color: ink).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.35,
            fontSize: TokensStrip.fontBody,
          ),
          decoration: FxInputDeco.insetGrouped(
            context,
            icon: Icons.notes_rounded,
            hint: 'Orientações curtas para o aluno',
            iconColor: iconColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Repetir última · ${memory.summary}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
