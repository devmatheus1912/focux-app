part of 'prescription_editor_sheet.dart';

extension on _PrescriptionEditorSheetState {
  Future<void> _openRepsSheet() async {
    if (!widget.enabled) return;
    final draft = TextEditingController(text: widget.repCtrl.text);
    final shortcuts = workoutBuilderRepShortcuts(_presetId);
    final brand = BrandPalette.softened(widget.primary);
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line =
        widget.isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final applied = await showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: widget.isDark,
          padding: EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            12,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              final current = draft.text.trim();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: widget.isDark),
                  const SizedBox(height: 6),
                  FxHomeSheetHeader(
                    isDark: widget.isDark,
                    title: prescriptionRepsLabel,
                    subtitle: prescriptionRepsSubtitle,
                    leading: Icon(
                      Icons.fitness_center_rounded,
                      color: brand,
                      size: FxSettingsLayout.iconSize,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  FxSettingsGroup(
                    accent: widget.primary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextFormField(
                          controller: draft,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setLocal(() {}),
                          onFieldSubmitted: (_) => Navigator.pop(ctx, true),
                          style: FxSettingsLayout.rowLabel(
                            color: fxScreenInk(context),
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            hintText: _selectedPreset.repeticoes,
                            hintStyle: FxSettingsLayout.rowValue(color: mute),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in shortcuts)
                        _RepShortcutChip(
                          label: option,
                          selected: current == option,
                          brand: brand,
                          line: line,
                          mute: mute,
                          onTap: () {
                            draft.text = option;
                            HapticFeedback.selectionClick();
                            setLocal(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(prescriptionAplicar),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (applied == true && mounted) {
      widget.repCtrl.text = draft.text.trim();
      setState(() {});
    }
    draft.dispose();
  }

  Future<void> _openObjetivoPicker() async {
    if (!widget.enabled) return;
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: prescriptionObjetivo,
      subtitle: prescriptionObjetivoSubtitle,
      headerIcon: Icons.flag_outlined,
      selected: _presetId,
      items: [
        for (final preset in workoutBuilderPresets)
          FxInsetPickerSheetItem(
            value: preset.id,
            label: preset.label,
            subtitle: preset.summary,
            icon: Icons.flag_outlined,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _presetId = picked);
    widget.onPresetSelected(picked);
  }

  Future<void> _openTipoSeriePicker() async {
    if (!widget.enabled) return;
    const tipos = ['NORMAL', 'SUPERSET', 'DROPSET'];
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: prescriptionTipoSerie,
      headerIcon: Icons.layers_outlined,
      selected: _tipoSerie.toUpperCase(),
      items: [
        for (final tipo in tipos)
          FxInsetPickerSheetItem(
            value: tipo,
            label: workoutTipoSerieLabel(tipo),
            subtitle: workoutTipoSerieSubtitle(tipo),
            icon: Icons.layers_outlined,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _tipoSerie = picked);
    widget.onTipoSerieChanged(picked);
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
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: prescriptionDescanso,
      headerIcon: Icons.timer_outlined,
      selected: atual,
      items: [
        for (final s in opcoesDescansoSeg)
          FxInsetPickerSheetItem(
            value: s,
            label: s == 0 ? 'Sem descanso' : '${s}s',
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _setRest(picked);
  }
}
