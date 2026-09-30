part of 'prescription_editor_sheet.dart';

class _PrescriptionEditorSheetState extends State<PrescriptionEditorSheet> {
  late final Listenable _fieldsListenable;
  late String _presetId;
  late String _tipoSerie;
  bool _showCarga = false;
  bool _showRpeAlvo = false;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _presetId = widget.presetId;
    _tipoSerie = widget.tipoSerie;
    _showCarga = widget.cargaCtrl.text.trim().isNotEmpty;
    _showRpeAlvo = widget.rpeAlvoCtrl?.text.trim().isNotEmpty == true;
    _showNotes = widget.observacoesCtrl.text.trim().isNotEmpty;
    _fieldsListenable = Listenable.merge([
      widget.seriesCtrl,
      widget.repCtrl,
      widget.descansoCtrl,
      widget.cargaCtrl,
      if (widget.rpeAlvoCtrl != null) widget.rpeAlvoCtrl!,
      widget.observacoesCtrl,
    ]);
    _fieldsListenable.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.cargaCtrl.text.trim().isNotEmpty) _showCarga = true;
      if (widget.rpeAlvoCtrl?.text.trim().isNotEmpty == true) {
        _showRpeAlvo = true;
      }
      if (widget.observacoesCtrl.text.trim().isNotEmpty) _showNotes = true;
    });
  }

  @override
  void dispose() {
    _fieldsListenable.removeListener(_onFieldsChanged);
    super.dispose();
  }

  WorkoutBuilderPreset get _selectedPreset =>
      workoutBuilderPresetById(_presetId);

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

  @override
  Widget build(BuildContext context) {
    final brand = BrandPalette.softened(widget.primary);
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line =
        widget.isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final ink = fxScreenInk(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        (widget.heightFactor ?? FxHomeSheetChrome.expandHeightFactor);
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
    final headerTitle =
        widget.title ??
        (widget.globalPresetMode
            ? prescriptionPadrao
            : prescriptionDoExercicio);
    final headerSubtitle =
        widget.contextSubtitle ?? _previewLine();
    final repsValue =
        widget.repCtrl.text.trim().isEmpty
            ? selectedPreset.repeticoes
            : widget.repCtrl.text.trim();
    final enabled = widget.enabled;
    final dropHint = _tipoSerie.toUpperCase() == 'DROPSET';

    final fields = <Widget>[
      if (widget.lastPrescription != null) ...[
        _RepeatPrescriptionTile(
          memory: widget.lastPrescription!,
          primary: widget.primary,
          brand: brand,
          isDark: widget.isDark,
          line: line,
          onApply: enabled ? widget.onApplyLastPrescription : null,
        ),
        const SizedBox(height: TokensStrip.s3),
      ],
      FxSettingsGroup(
        header: prescriptionGroupHeader,
        accent: widget.primary,
        children: [
          if (widget.showPresets)
            FxSettingsTile(
              icon: Icons.flag_outlined,
              label: prescriptionObjetivo,
              value: selectedPreset.label,
              mute: mute,
              line: line,
              accent: brand,
              picker: true,
              onTap: enabled ? _openObjetivoPicker : null,
            ),
          _PrescriptionStepperRow(
            label: prescriptionSeries,
            icon: Icons.format_list_numbered_rounded,
            iconColor: brand,
            value: '$seriesValue',
            line: line,
            ink: ink,
            mute: mute,
            onDecrement:
                enabled
                    ? () =>
                        _setSeries(adjustPrescriptionSeries(seriesValue, -1))
                    : null,
            onIncrement:
                enabled
                    ? () =>
                        _setSeries(adjustPrescriptionSeries(seriesValue, 1))
                    : null,
          ),
          FxSettingsTile(
            icon: Icons.fitness_center_rounded,
            label: prescriptionRepsLabel,
            value: repsValue,
            mute: mute,
            line: line,
            accent: brand,
            picker: true,
            numeric: true,
            onTap: enabled ? () => _openRepsSheet() : null,
          ),
          _PrescriptionStepperRow(
            label: prescriptionDescanso,
            icon: Icons.timer_outlined,
            iconColor: brand,
            value: '${restValue}s',
            line: line,
            ink: ink,
            mute: mute,
            onDecrement:
                enabled
                    ? () => _setRest(
                      adjustPrescriptionRestSeconds(restValue, -15),
                    )
                    : null,
            onIncrement:
                enabled
                    ? () => _setRest(
                      adjustPrescriptionRestSeconds(restValue, 15),
                    )
                    : null,
            showDivider: false,
          ),
        ],
      ),
      const SizedBox(height: FxSettingsLayout.groupGap),
      FxSettingsGroup(
        header: prescriptionMaisDetalhes,
        accent: widget.primary,
        footer:
            dropHint
                ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.groupPadH,
                  ),
                  child: Text(
                    prescriptionDropHint,
                    style: FxSettingsLayout.footer(color: mute),
                  ),
                )
                : null,
        children: [
          FxSettingsTile(
            icon: Icons.layers_outlined,
            label: prescriptionTipoSerie,
            value: workoutTipoSerieLabel(_tipoSerie),
            mute: mute,
            line: line,
            accent: brand,
            picker: true,
            onTap: enabled ? _openTipoSeriePicker : null,
          ),
          if (_tipoSerie.toUpperCase() == 'SUPERSET')
            _PrescriptionValueRow(
              label: prescriptionGrupoSuperset,
              icon: Icons.link_rounded,
              iconColor: brand,
              controller: widget.grupoSupersetCtrl,
              hint: prescriptionGrupoHint,
              line: line,
              ink: ink,
              mute: mute,
              keyboardType: TextInputType.number,
            ),
          if (_showCarga)
            _PrescriptionValueRow(
              label: prescriptionCarga,
              icon: Icons.scale_rounded,
              iconColor: brand,
              controller: widget.cargaCtrl,
              hint: prescriptionOpcional,
              line: line,
              ink: ink,
              mute: mute,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              showDivider: true,
            )
          else
            _PrescriptionExpandRow(
              label: prescriptionAddCarga,
              icon: Icons.scale_rounded,
              iconColor: brand,
              line: line,
              mute: mute,
              onTap: () {
                if (!enabled) return;
                HapticFeedback.selectionClick();
                setState(() => _showCarga = true);
              },
              showDivider: true,
            ),
          if (widget.rpeAlvoCtrl != null) ...[
            if (_showRpeAlvo)
              _PrescriptionValueRow(
                label: prescriptionRpe,
                icon: Icons.speed_rounded,
                iconColor: brand,
                controller: widget.rpeAlvoCtrl!,
                hint: prescriptionOpcional,
                line: line,
                ink: ink,
                mute: mute,
                keyboardType: TextInputType.number,
                showDivider: _showNotes,
              )
            else
              _PrescriptionExpandRow(
                label: prescriptionAddRpe,
                icon: Icons.speed_rounded,
                iconColor: brand,
                line: line,
                mute: mute,
                onTap: () {
                  if (!enabled) return;
                  HapticFeedback.selectionClick();
                  setState(() => _showRpeAlvo = true);
                },
                showDivider: true,
              ),
          ],
          if (_showNotes)
            _PrescriptionNotesField(
              controller: widget.observacoesCtrl,
              iconColor: brand,
              ink: ink,
            )
          else
            _PrescriptionExpandRow(
              label: prescriptionAddNotas,
              icon: Icons.notes_rounded,
              iconColor: brand,
              line: line,
              mute: mute,
              onTap: () {
                if (!enabled) return;
                HapticFeedback.selectionClick();
                setState(() => _showNotes = true);
              },
              showDivider: false,
            ),
        ],
      ),
      if (widget.belowFields != null) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        widget.belowFields!,
      ],
    ];

    final headerWidgets = <Widget>[
      FxHomeSheetHandle(isDark: widget.isDark),
      const SizedBox(height: 6),
      FxHomeSheetHeader(
        isDark: widget.isDark,
        title: headerTitle,
        subtitle: headerSubtitle,
        leading: Icon(
          Icons.edit_note_rounded,
          color: brand,
          size: FxSettingsLayout.iconSize,
        ),
        trailing:
            widget.canPop
                ? null
                : IconButton(
                  tooltip: prescriptionFechar,
                  onPressed: null,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      FxHomeSheetChrome.touchTarget,
                      FxHomeSheetChrome.touchTarget,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: FxSettingsLayout.iconSize,
                    color:
                        widget.isDark
                            ? EagleTokens.darkInkMute
                            : TokensStrip.textSecondary,
                  ),
                ),
      ),
      const SizedBox(height: TokensStrip.s3),
    ];

    final Widget surfaceChild;
    if (widget.stickyFooter == null) {
      surfaceChild = SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardInset + 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...headerWidgets, ...fields],
        ),
      );
    } else {
      surfaceChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...headerWidgets,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboardInset + 8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: fields,
              ),
            ),
          ),
          widget.stickyFooter!,
        ],
      );
    }

    return PopScope(
      canPop: widget.canPop,
      child: FxHomeSheetSurface(
        isDark: widget.isDark,
        maxHeight: maxHeight,
        expand: widget.expand || widget.stickyFooter != null,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          12,
        ),
        child: surfaceChild,
      ),
    );
  }
}

