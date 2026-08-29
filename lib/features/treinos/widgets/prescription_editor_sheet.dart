import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
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
    return '$series×$reps · ${rest}s';
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
    final fieldStyle = FocuxHubTypography.body(color: widget.ink).copyWith(
      fontWeight: FontWeight.w700,
    );

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      expand: true,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
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
          _PreviewStrip(
            presetLabel: selectedPreset.label,
            summary: _previewLabel,
            brand: brand,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 12),
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
                      isDark: widget.isDark,
                      onApply: widget.onApplyLastPrescription,
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                  ],
                  Text(
                    'Objetivo',
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
                      padding: const EdgeInsets.all(10),
                      child: AlunoSegmentedChoice(
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
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FxSettingsLayout.groupPadH,
                    ),
                    child: Text(
                      selectedPreset.summary,
                      style: FxSettingsLayout.footer(color: mute),
                    ),
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    accent: widget.primary,
                    caption: 'Séries, repetições e descanso',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _VolumeField(
                              label: 'Séries',
                              controller: widget.seriesCtrl,
                              keyboardType: TextInputType.number,
                              style: fieldStyle,
                              isDark: widget.isDark,
                              line: line,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VolumeField(
                              label: 'Repetições',
                              controller: widget.repCtrl,
                              style: fieldStyle,
                              isDark: widget.isDark,
                              line: line,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _VolumeField(
                              label: 'Descanso (s)',
                              controller: widget.descansoCtrl,
                              keyboardType: TextInputType.number,
                              style: fieldStyle,
                              isDark: widget.isDark,
                              line: line,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VolumeField(
                              label: 'Carga (kg)',
                              controller: widget.cargaCtrl,
                              hint: 'Opcional',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: fieldStyle,
                              isDark: widget.isDark,
                              line: line,
                            ),
                          ),
                        ],
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
                      padding: const EdgeInsets.all(10),
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
                    _VolumeField(
                      label: 'Grupo do superset',
                      controller: widget.grupoSupersetCtrl,
                      hint: 'Mesmo número em exercícios juntos',
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                      isDark: widget.isDark,
                      line: line,
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
                  FxSettingsGroup(
                    accent: widget.primary,
                    caption: 'Observações de execução',
                    children: [
                      TextFormField(
                        controller: widget.observacoesCtrl,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        minLines: 2,
                        maxLines: 4,
                        style: fieldStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FxSettingsLayout.groupPadH,
                    ),
                    child: Text(
                      'Dica: ${selectedPreset.observacoes}',
                      style: FxSettingsLayout.footer(color: mute),
                    ),
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

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({
    required this.presetLabel,
    required this.summary,
    required this.brand,
    required this.isDark,
  });

  final String presetLabel;
  final String summary;
  final Color brand;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, color: brand, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$presetLabel · $summary',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: brand, size: 18),
          ],
        ),
      ),
    );
  }
}

class _VolumeField extends StatelessWidget {
  const _VolumeField({
    required this.label,
    required this.controller,
    required this.style,
    required this.isDark,
    required this.line,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextStyle style;
  final bool isDark;
  final Color line;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final fill = isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: FxSettingsLayout.subhead(color: mute).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: style,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FocuxHubTypography.bodyMuted(
              color: mute.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: line.withValues(alpha: 0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: line.withValues(alpha: 0.65)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
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
