part of 'treino_detail_screen.dart';

class _EditPrescriptionSheet extends StatefulWidget {
  const _EditPrescriptionSheet({
    required this.treinoId,
    required this.item,
    required this.isDark,
    required this.repo,
    this.outrosNoBloco = const [],
  });

  final int treinoId;
  final TreinoExercicioItem item;
  final bool isDark;
  final TreinoRepository repo;

  /// Outros exercícios do mesmo bloco (para "Aplicar a todo o bloco").
  final List<TreinoExercicioItem> outrosNoBloco;

  @override
  State<_EditPrescriptionSheet> createState() => _EditPrescriptionSheetState();
}

class _EditPrescriptionSheetState extends State<_EditPrescriptionSheet> {
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repCtrl;
  late final TextEditingController _descansoCtrl;
  late final TextEditingController _cargaCtrl;
  late final TextEditingController _rpeAlvoCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _supersetCtrl;
  late String _tipoSerie;
  late String _presetId;
  bool _saving = false;
  bool _videoBusy = false;
  bool _aplicarAoBloco = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _seriesCtrl = TextEditingController(text: '${item.series}');
    _repCtrl = TextEditingController(text: item.repeticoes);
    _descansoCtrl = TextEditingController(
      text: '${item.descansoSegundos ?? 60}',
    );
    _cargaCtrl = TextEditingController(
      text:
          item.cargaKg != null && item.cargaKg! > 0
              ? item.cargaKg!.toString()
              : '',
    );
    _rpeAlvoCtrl = TextEditingController(
      text: item.rpeAlvo != null ? '${item.rpeAlvo}' : '',
    );
    _obsCtrl = TextEditingController(text: item.observacoes ?? '');
    _supersetCtrl = TextEditingController(text: '${item.grupoSuperset ?? 1}');
    _tipoSerie = item.tipoSerie;
    _presetId = matchWorkoutBuilderPresetId(
      series: item.series,
      repeticoes: item.repeticoes,
      descansoSegundos: item.descansoSegundos ?? 60,
    );
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    _cargaCtrl.dispose();
    _rpeAlvoCtrl.dispose();
    _obsCtrl.dispose();
    _supersetCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String id) {
    final preset = workoutBuilderPresetById(id);
    setState(() {
      _presetId = id;
      _seriesCtrl.text = '${preset.series}';
      _repCtrl.text = preset.repeticoes;
      _descansoCtrl.text = '${preset.descansoSegundos}';
    });
  }

  Future<void> _save() async {
    if (_saving || _videoBusy) return;
    final series = int.tryParse(_seriesCtrl.text) ?? widget.item.series;
    final descansoSegundos = int.tryParse(_descansoCtrl.text) ?? 60;
    final rejection = treinoPrescriptionRejection(
      series: series,
      descansoSegundos: descansoSegundos,
    );
    if (rejection != null) {
      FeedbackHelper.showError(context, rejection);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repo.atualizarExercicioPrescricao(
        widget.treinoId,
        widget.item.id,
        series: series,
        repeticoes: _repCtrl.text.trim(),
        descansoSegundos: descansoSegundos,
        cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
        rpeAlvo: int.tryParse(_rpeAlvoCtrl.text.trim()),
        observacoes: _obsCtrl.text,
        tipoSerie: _tipoSerie,
        grupoSuperset:
            _tipoSerie == 'SUPERSET' ? int.tryParse(_supersetCtrl.text) : null,
      );
      final carga = double.tryParse(_cargaCtrl.text.replaceAll(',', '.'));
      final reps = _repCtrl.text.trim();
      final aquecimento = widget.item.seriesLinhas.where((linha) => linha.aquecimento).toList();
      final validasAtuais = widget.item.seriesLinhas.where((linha) => !linha.aquecimento).toList();
      final quantidadeValidas = (series - aquecimento.length).clamp(1, 20).toInt();
      final validas = [
        for (var i = 0; i < quantidadeValidas; i++)
          SeriePrescrita(
            numero: i + 1,
            repeticoes: reps.isEmpty ? (i < validasAtuais.length ? validasAtuais[i].repeticoes : '8-12') : reps,
            cargaKg: carga ?? (i < validasAtuais.length ? validasAtuais[i].cargaKg : null),
          ),
      ];
      final linhas = [...aquecimento, ...validas];
      await widget.repo.salvarSeries(
        widget.treinoId,
        widget.item.id,
        linhas: [
          for (var i = 0; i < linhas.length; i++) linhas[i].comNumero(i + 1),
        ],
        bloco: widget.item.bloco,
        descansoSegundos: descansoSegundos,
      );
      if (_aplicarAoBloco) {
        for (final outro in widget.outrosNoBloco) {
          await _aplicarEm(
            outro,
            series: series,
            repeticoes: reps,
            descansoSegundos: descansoSegundos,
          );
        }
      }
      AnalyticsService.instance.track(
        ProductEvents.treinoPrescriptionSaved,
        props: {
          'id': widget.treinoId,
          'itemId': widget.item.id,
          'tipoSerie': _tipoSerie,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Aplica só séries, repetições e descanso: carga, RPE e observações de cada
  /// exercício continuam como estavam.
  Future<void> _aplicarEm(
    TreinoExercicioItem outro, {
    required int series,
    required String repeticoes,
    required int descansoSegundos,
  }) async {
    await widget.repo.atualizarExercicioPrescricao(
      widget.treinoId,
      outro.id,
      series: series,
      repeticoes: repeticoes,
      descansoSegundos: descansoSegundos,
      cargaKg: outro.cargaKg,
      rpeAlvo: outro.rpeAlvo,
      observacoes: outro.observacoes ?? '',
      tipoSerie: outro.tipoSerie,
      grupoSuperset: outro.tipoSerie == 'SUPERSET' ? outro.grupoSuperset : null,
    );
    await widget.repo.salvarSeries(
      widget.treinoId,
      outro.id,
      linhas: [
        for (var i = 1; i <= series; i++)
          SeriePrescrita(
            numero: i,
            repeticoes: repeticoes,
            cargaKg: outro.cargaKg,
          ),
      ],
      bloco: outro.bloco,
      descansoSegundos: descansoSegundos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, widget.isDark);
    final busy = _saving || _videoBusy;

    return PrescriptionEditorSheet(
      isDark: widget.isDark,
      primary: primary,
      ink: chrome.ink,
      title: 'Editar prescrição',
      contextSubtitle: widget.item.exercicio.nomeDisplay,
      presetId: _presetId,
      tipoSerie: _tipoSerie,
      globalPresetMode: false,
      lastPrescription: null,
      seriesCtrl: _seriesCtrl,
      repCtrl: _repCtrl,
      descansoCtrl: _descansoCtrl,
      cargaCtrl: _cargaCtrl,
      rpeAlvoCtrl: _rpeAlvoCtrl,
      observacoesCtrl: _obsCtrl,
      grupoSupersetCtrl: _supersetCtrl,
      onPresetSelected: _applyPreset,
      onTipoSerieChanged: (value) => setState(() => _tipoSerie = value),
      onApplyLastPrescription: () {},
      expand: true,
      heightFactor: 0.88,
      canPop: !busy,
      enabled: !busy,
      bloco: widget.item.bloco,
      outrosNoBloco: widget.outrosNoBloco.length,
      aplicarAoBloco: _aplicarAoBloco,
      onAplicarAoBlocoChanged: (v) => _aplicarAoBloco = v,
      belowFields: TreinoPrescriptionVideoBlock(
        treinoId: widget.treinoId,
        exercicio: widget.item.exercicio,
        isDark: widget.isDark,
        busy: _saving,
        onBusyChanged: (value) {
          if (mounted) setState(() => _videoBusy = value);
        },
      ),
      stickyFooter: FxLiquidPrimaryButton(
        label: treinoPrescriptionSaveLabel(),
        loading: _saving,
        loadingLabel: 'Salvando…',
        onPressed: busy ? null : _save,
      ),
    );
  }
}
