part of 'prescription_editor_sheet.dart';

class _PrescriptionEditorSheetState extends State<PrescriptionEditorSheet> {
  late final Listenable _fieldsListenable;
  late String _presetId;
  late String _tipoSerie;
  bool _showCarga = false;
  bool _showRpeAlvo = false;
  bool _showNotes = false;
  bool _maisAberto = false;
  late bool _aplicarAoBloco;

  @override
  void initState() {
    super.initState();
    _presetId = widget.presetId;
    _tipoSerie = widget.tipoSerie;
    _aplicarAoBloco = widget.aplicarAoBloco;
    _maisAberto = maisDetalhesPreenchidos(
      carga: widget.cargaCtrl.text,
      rpe: widget.rpeAlvoCtrl?.text ?? '',
      observacoes: widget.observacoesCtrl.text,
      tipoSerie: widget.tipoSerie,
    );
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
          _PrescriptionChipsRow(
            label: prescriptionRepsLabel,
            icon: Icons.fitness_center_rounded,
            iconColor: brand,
            ink: ink,
            line: line,
            chips: FxQuickChips<String>(
              itens: atalhosRepeticoes(widget.bloco),
              selecionado: repsValue.trim(),
              outroSelecionado: !repeticoesEhAtalho(widget.bloco, repsValue),
              outroRotulo: repeticoesEhAtalho(widget.bloco, repsValue)
                  ? 'Outro'
                  : repsValue,
              onSelecionar: (v) {
                if (!enabled) return;
                widget.repCtrl.text = v;
                HapticFeedback.selectionClick();
                setState(() {});
              },
              onOutro: enabled ? () => _openRepsSheet() : null,
            ),
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
            showDivider: true,
          ),
          _PrescriptionChipsRow(
            label: '',
            icon: null,
            iconColor: brand,
            ink: ink,
            line: line,
            showDivider: false,
            chips: FxQuickChips<int>(
              itens: atalhosDescansoSeg(widget.bloco),
              selecionado: restValue,
              rotuloDe: (v) => '${v}s',
              outroSelecionado: !descansoEhAtalho(widget.bloco, restValue),
              outroRotulo: descansoEhAtalho(widget.bloco, restValue)
                  ? 'Outro'
                  : '${restValue}s',
              onSelecionar: (v) {
                if (enabled) _setRest(v);
              },
              onOutro: enabled ? _openDescansoPicker : null,
            ),
          ),
        ],
      ),
      if (widget.outrosNoBloco > 0 &&
          widget.onAplicarAoBlocoChanged != null) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: Icons.library_add_check_outlined,
              label: 'Aplicar a todo o bloco',
              subtitle: widget.outrosNoBloco == 1
                  ? 'Séries, repetições e descanso do outro exercício do bloco'
                  : 'Séries, repetições e descanso dos outros ${widget.outrosNoBloco} do bloco',
              value: '',
              mute: mute,
              line: line,
              accent: brand,
              showDivider: false,
              accessory: Switch.adaptive(
                value: _aplicarAoBloco,
                onChanged: enabled
                    ? (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _aplicarAoBloco = v);
                        widget.onAplicarAoBlocoChanged!(v);
                      }
                    : null,
              ),
              onTap: enabled
                  ? () {
                      final v = !_aplicarAoBloco;
                      HapticFeedback.selectionClick();
                      setState(() => _aplicarAoBloco = v);
                      widget.onAplicarAoBlocoChanged!(v);
                    }
                  : null,
            ),
          ],
        ),
      ],
      const SizedBox(height: FxSettingsLayout.groupGap),
      if (!_maisAberto)
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: Icons.tune_rounded,
              label: prescriptionMaisDetalhes,
              subtitle: 'Tipo de série, carga, RPE e observações',
              value: '',
              mute: mute,
              line: line,
              accent: brand,
              disclosure: true,
              showDivider: false,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _maisAberto = true);
              },
            ),
          ],
        )
      else
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
