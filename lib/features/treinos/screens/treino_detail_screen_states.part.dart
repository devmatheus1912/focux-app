part of 'treino_detail_screen.dart';

class _EditPrescriptionSheet extends StatefulWidget {
  const _EditPrescriptionSheet({
    required this.treinoId,
    required this.item,
    required this.isDark,
    required this.repo,
    this.outrosNoBloco = const [],
    this.adicionarPapel,
  });

  final int treinoId;
  final TreinoExercicioItem item;
  final bool isDark;
  final TreinoRepository repo;

  /// Outros exercícios do mesmo bloco (para "Aplicar a todo o bloco").
  final List<TreinoExercicioItem> outrosNoBloco;

  /// Atalho do menu ("Adicionar aquecimento"/"back-off"): abre com o grupo já posto.
  final String? adicionarPapel;

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

  /// Controles das válidas: a linha "Válidas" dos grupos rola até eles.
  final _validasKey = GlobalKey();

  /// Aquecimento e ajuste (antes das válidas) e back-off (depois).
  late List<GrupoDeSeries> _antes;
  late List<GrupoDeSeries> _depois;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final extras = gruposExtras(item.seriesLinhas);
    _antes = extras.antes;
    _depois = extras.depois;
    // Os controles da folha são as válidas; os outros grupos ficam na lista.
    final validas = item.seriesLinhas
        .where((l) => l.papel == PapelDaSerie.valida)
        .toList();
    final temLinhas = item.seriesLinhas.isNotEmpty;
    _seriesCtrl = TextEditingController(
      text: '${temLinhas ? validas.length.clamp(1, 20) : item.series}',
    );
    _repCtrl = TextEditingController(
      text: validas.isNotEmpty ? validas.first.repeticoes : item.repeticoes,
    );
    _descansoCtrl = TextEditingController(
      text: '${item.descansoSegundos ?? 60}',
    );
    final carga = validas.isNotEmpty ? validas.first.cargaKg : item.cargaKg;
    _cargaCtrl = TextEditingController(
      text: carga != null && carga > 0 ? formatBrDecimal(carga) : '',
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
    final papel = widget.adicionarPapel;
    if (papel != null) {
      final novo = grupoSugerido(
        papel,
        seriesValidas: int.tryParse(_seriesCtrl.text) ?? item.series,
        repsValidas: _repCtrl.text.trim().isEmpty ? '8-12' : _repCtrl.text.trim(),
        cargaValidas: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
        descansoValidas: item.descansoSegundos,
      );
      if (papel == PapelDaSerie.backoff) {
        _depois = [..._depois, novo];
      } else {
        _antes = [novo, ..._antes];
      }
    }
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
      final validasAtuais = widget.item.seriesLinhas
          .where((linha) => linha.papel == PapelDaSerie.valida)
          .toList();
      final quantidadeValidas = series.clamp(1, 20).toInt();
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
      // Ordem da execução: aquecimento/ajuste, válidas, back-off.
      final linhas = [
        ...desagruparSeries(_antes),
        ...validas,
        ...desagruparSeries(_depois),
      ];
      await widget.repo.salvarSeries(
        widget.treinoId,
        widget.item.id,
        linhas: [
          for (var i = 0; i < linhas.length; i++) linhas[i].comNumero(i + 1),
        ],
        bloco: widget.item.bloco,
        descansoSegundos: descansoSegundos,
      );
      Future<void> Function()? desfazer;
      if (_aplicarAoBloco && widget.outrosNoBloco.isNotEmpty) {
        final anteriores = [...widget.outrosNoBloco];
        for (final outro in anteriores) {
          await _aplicarEm(
            outro,
            series: series,
            repeticoes: reps,
            descansoSegundos: descansoSegundos,
          );
        }
        // Desfazer devolve a prescrição e as séries de cada um como estavam.
        final repo = widget.repo;
        final treinoId = widget.treinoId;
        desfazer = () => _restaurarPrescricoes(repo, treinoId, anteriores);
      }
      AnalyticsService.instance.track(
        ProductEvents.treinoPrescriptionSaved,
        props: {
          'id': widget.treinoId,
          'itemId': widget.item.id,
          'tipoSerie': _tipoSerie,
        },
      );
      if (mounted) {
        Navigator.pop<Object>(
          context,
          desfazer == null
              ? true
              : PrescricaoAplicadaAoBloco(widget.outrosNoBloco.length, desfazer),
        );
      }
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
    GrupoDeSeries semCarga(GrupoDeSeries g) => g.copyWith(limparCarga: true);
    await widget.repo.salvarSeries(
      widget.treinoId,
      outro.id,
      linhas: desagruparSeries([
        ..._antes.map(semCarga),
        GrupoDeSeries(
          papel: PapelDaSerie.valida,
          series: series,
          repeticoes: repeticoes,
          cargaKg: outro.cargaKg,
        ),
        ..._depois.map(semCarga),
      ]),
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
      nomesNoBloco: [
        for (final o in widget.outrosNoBloco) o.exercicio.nomeDisplay,
      ],
      validasKey: _validasKey,
      gruposDeSerie: GruposDeSerieEditor(
        onVerValidas: () {
          final alvo = _validasKey.currentContext;
          if (alvo == null) return;
          Scrollable.ensureVisible(
            alvo,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        },
        antes: _antes,
        depois: _depois,
        enabled: !busy,
        resumoValidas:
            '${_seriesCtrl.text} × ${_repCtrl.text.trim().isEmpty ? '8-12' : _repCtrl.text.trim()}',
        sugerir: (papel) => grupoSugerido(
          papel,
          seriesValidas: int.tryParse(_seriesCtrl.text) ?? 3,
          repsValidas: _repCtrl.text.trim().isEmpty ? '8-12' : _repCtrl.text.trim(),
          cargaValidas: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
          descansoValidas: int.tryParse(_descansoCtrl.text),
        ),
        onChanged: (antes, depois) => setState(() {
          _antes = antes;
          _depois = depois;
        }),
      ),
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

/// Resultado da folha quando a prescrição foi aplicada a outros exercícios:
/// quantos mudaram e como desfazer.
class PrescricaoAplicadaAoBloco {
  const PrescricaoAplicadaAoBloco(this.quantos, this.desfazer);

  final int quantos;
  final Future<void> Function() desfazer;
}
