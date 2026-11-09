part of 'prescription_editor_sheet.dart';

class _PrescriptionEditorSheetState extends State<PrescriptionEditorSheet> {
  late final Listenable _fieldsListenable;
  late String _presetId;
  late String _tipoSerie;
  bool _showNotes = false;
  bool _maisAberto = false;
  late bool _aplicarAoBloco;
  late ParametrosDoMetodo _parametros;

  void _mudarParametros(ParametrosDoMetodo novos) {
    setState(() => _parametros = novos);
    widget.onParametrosChanged?.call(novos);
  }

  void _mudarTecnica(String tecnica) {
    HapticFeedback.selectionClick();
    setState(() => _tipoSerie = tecnica);
    widget.onTipoSerieChanged(tecnica);
  }

  @override
  void initState() {
    super.initState();
    _presetId = widget.presetId;
    _tipoSerie = widget.tipoSerie;
    _aplicarAoBloco = widget.aplicarAoBloco;
    _parametros = widget.parametrosIniciais;
    _maisAberto = maisDetalhesPreenchidos(
      carga: '',
      rpe: widget.rpeAlvoCtrl?.text ?? '',
      observacoes: widget.observacoesCtrl.text,
      tipoSerie: widget.tipoSerie,
    );
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
      // O objetivo é da sessão (cabeçalho do editor); aqui, só os números.
      FxSettingsGroup(
        key: widget.validasKey,
        accent: widget.primary,
        children: [
          _PrescriptionStepperRow(
            label: prescriptionSeries,
            icon: FxIcons.listaNumerada,
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
            icon: FxIcons.repetir,
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
          // Carga é o centro da progressão: fica junto da prescrição.
          _PrescriptionValueRow(
            label: prescriptionCarga,
            icon: FxIcons.balanca,
            iconColor: brand,
            controller: widget.cargaCtrl,
            hint: prescriptionSemCarga,
            line: line,
            ink: ink,
            mute: mute,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            showDivider: true,
          ),
          // Descanso só em chips, em ordem; valor fora do atalho entra no lugar.
          _PrescriptionChipsRow(
            label: prescriptionDescanso,
            icon: FxIcons.cronometro,
            iconColor: brand,
            ink: ink,
            line: line,
            showDivider: false,
            chips: FxQuickChips<int>(
              itens: descansoComValorNoLugar(widget.bloco, restValue),
              selecionado: restValue,
              rotuloDe: (v) => '$v s',
              outroRotulo: 'Outro',
              onSelecionar: (v) {
                if (enabled) _setRest(v);
              },
              onOutro: enabled ? _openDescansoPicker : null,
            ),
          ),
        ],
      ),
      if (widget.gruposDeSerie != null) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        widget.gruposDeSerie!,
      ],
      const SizedBox(height: FxSettingsLayout.groupGap),
      _metodo(),
      if (widget.outrosNoBloco > 0 &&
          widget.onAplicarAoBlocoChanged != null) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: FxIcons.checklist,
              label: 'Aplicar a todo o bloco',
              subtitle: prescricaoAplicarAoBlocoTexto(widget.nomesNoBloco, widget.outrosNoBloco),
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
              // A linha toda liga e desliga (sem seta: o interruptor já diz).
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
              icon: FxIcons.filtros,
              label: prescriptionMaisDetalhes,
              subtitle: prescriptionMaisDetalhesSubtitulo,
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
        children: [
          if (widget.rpeAlvoCtrl != null)
            _PrescriptionChipsRow(
              label: prescriptionRpe,
              icon: FxIcons.velocidade,
              iconColor: brand,
              ink: ink,
              line: line,
              showDivider: true,
              chips: FxQuickChips<int>(
                // 10 = falha (back-off, método de intensidade).
                itens: const [6, 7, 8, 9, 10],
                selecionado: int.tryParse(widget.rpeAlvoCtrl!.text.trim()),
                outroRotulo: prescriptionSemRpe,
                outroSelecionado: widget.rpeAlvoCtrl!.text.trim().isEmpty,
                onSelecionar: (v) {
                  if (!enabled) return;
                  widget.rpeAlvoCtrl!.text = '$v';
                  HapticFeedback.selectionClick();
                  setState(() {});
                },
                onOutro: enabled
                    ? () {
                        widget.rpeAlvoCtrl!.clear();
                        HapticFeedback.selectionClick();
                        setState(() {});
                      }
                    : null,
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
              label: prescriptionAddNotas,
              icon: FxIcons.notas,
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
          FxIcons.anotar,
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
                    FxIcons.fechar,
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
