part of 'prescription_editor_sheet.dart';

extension on _PrescriptionEditorSheetState {
  Future<void> _openRepsSheet() async {
    if (!widget.enabled) return;
    final texto = await escolherRepeticoes(
      context,
      atual: widget.repCtrl.text,
      atalhos: workoutBuilderRepShortcuts(_presetId),
      dica: _selectedPreset.repeticoes,
    );
    if (texto == null || !mounted) return;
    widget.repCtrl.text = texto;
    setState(() {});
  }

  String _previewLine() {
    final preset = _selectedPreset;
    final series =
        widget.seriesCtrl.text.trim().isEmpty
            ? '${preset.series}'
            : widget.seriesCtrl.text.trim();
    final reps =
        widget.repCtrl.text.trim().isEmpty
            ? preset.repeticoes
            : widget.repCtrl.text.trim();
    final rest =
        widget.descansoCtrl.text.trim().isEmpty
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
}

extension _DescansoPicker on _PrescriptionEditorSheetState {
  Future<void> _openDescansoPicker() async {
    if (!widget.enabled) return;
    final atual = parsePrescriptionInt(widget.descansoCtrl.text, fallback: 60);
    final picked = await escolherDescanso(context, atual: atual);
    if (picked == null || !mounted) return;
    _setRest(picked);
  }
}
