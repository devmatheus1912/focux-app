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
  late String _tipoSerie;
  late ParametrosDoMetodo _parametros;
  late String _presetId;
  bool _saving = false;
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
    _tipoSerie = tecnicaParaApi(item.metodo.tecnica);
    _parametros = ParametrosDoMetodo.de(item.metodo);
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
    if (_saving) return;
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
        tecnicaQuedas: _tipoSerie == 'DROPSET' ? _parametros.quedas : null,
        tecnicaReducaoPct: _tipoSerie == 'DROPSET' ? _parametros.reducaoPct : null,
        tecnicaPausaS: _tipoSerie == 'RESTPAUSE' ? _parametros.pausaS : null,
        tecnicaMiniSeries: _tipoSerie == 'RESTPAUSE' ? _parametros.miniSeries : null,
      );
      final carga = double.tryParse(_cargaCtrl.text.replaceAll(',', '.'));
      final reps = _repCtrl.text.trim();
      final aquecimento = widget.item.seriesLinhas.where((linha) => linha.aquecimento).toList();
      final validasAtuais = widget.item.seriesLinhas.where((linha) => !linha.aquecimento).toList();
      final quantidadeValidas = (series - aquecimento.length).clamp(1, 20).toInt();
      // Pirâmide: cada série com a sua meta (reps e carga mudam a cada série).
      final piramide = _tipoSerie == 'PIRAMIDE'
          ? linhasDaPiramide(
              series: quantidadeValidas,
              crescente: _parametros.piramideCrescente,
              repsBase: reps.isEmpty ? '8-12' : reps,
              carga: carga,
            )
          : null;
      final validas = [
        for (var i = 0; i < quantidadeValidas; i++)
          SeriePrescrita(
            numero: i + 1,
            repeticoes: piramide?[i].reps ??
                (reps.isEmpty ? (i < validasAtuais.length ? validasAtuais[i].repeticoes : '8-12') : reps),
            cargaKg: piramide?[i].carga ?? carga ?? (i < validasAtuais.length ? validasAtuais[i].cargaKg : null),
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
      tipoSerie: tecnicaParaApi(outro.metodo.tecnica),
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
    final busy = _saving;

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
      onPresetSelected: _applyPreset,
      onTipoSerieChanged: (value) => setState(() => _tipoSerie = value),
      parametrosIniciais: _parametros,
      onParametrosChanged: (p) => _parametros = p,
      onApplyLastPrescription: () {},
      expand: true,
      heightFactor: 0.88,
      canPop: !busy,
      enabled: !busy,
      bloco: widget.item.bloco,
      outrosNoBloco: widget.outrosNoBloco.length,
      aplicarAoBloco: _aplicarAoBloco,
      onAplicarAoBlocoChanged: (v) => _aplicarAoBloco = v,

      stickyFooter: FxLiquidPrimaryButton(
        label: treinoPrescriptionSaveLabel(),
        loading: _saving,
        loadingLabel: 'Salvando…',
        onPressed: busy ? null : _save,
      ),
    );
  }
}
