part of 'prescription_editor_sheet.dart';

/// Seção "Método": progressão das válidas (vale para o conjunto) e técnica de
/// intensidade (dentro da série), com só os parâmetros dela e em quais séries.
extension _MetodoDaPrescricao on _PrescriptionEditorSheetState {
  /// Uma fileira de escolhas com rótulo ("Quedas: 1 · 2 · 3").
  Widget _parametro<T>(String rotulo, Map<T, String> opcoes, T atual, ValueChanged<T> aoEscolher) {
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.groupPadH, TokensStrip.s1, FxSettingsLayout.groupPadH, TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rotulo.isNotEmpty) ...[
            Text(rotulo, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
            const SizedBox(height: TokensStrip.s1),
          ],
          FxChoiceStrip<T>(
            quebrar: true,
            itens: [for (final e in opcoes.entries) FxChoiceItem(value: e.key, label: e.value)],
            selecionado: atual,
            onSelecionar: widget.enabled ? aoEscolher : (_) {},
          ),
        ],
      ),
    );
  }

  int get _validas => int.tryParse(widget.seriesCtrl.text.trim())?.clamp(1, 20) ?? 1;

  /// Só a edição de um exercício já no treino grava progressão e séries; no
  /// "Adicionar exercício" a técnica entra em todas as válidas, como antes.
  bool get _metodoCompleto => widget.onParametrosChanged != null;

  Widget _metodo() {
    final tecnica = tecnicaDe(_tipoSerie);
    final p = _parametros;
    return FxSettingsGroup(
      header: prescriptionMetodo,
      accent: widget.primary,
      children: [
        if (_metodoCompleto)
          _parametro<Progressao>(
            prescriptionMetodoProgressao,
            {for (final v in Progressao.values) v: rotuloDaProgressao(v)},
            p.progressao,
            (v) {
              HapticFeedback.selectionClick();
              _mudarParametros(p.copyWith(progressao: v));
            },
          ),
        _parametro<Tecnica>(
          prescriptionMetodoTecnica,
          {for (final t in Tecnica.values) t: rotuloDaTecnica(t)},
          tecnica,
          (t) {
            _mudarTecnica(tecnicaParaApi(t));
            // Técnica nova volta ao padrão dela ("só a última" ou "todas").
            _mudarParametros(p.copyWith(limparEmQuais: true, escolhidas: const {}));
          },
        ),
        ..._parametrosDaTecnica(tecnica, p),
        if (_metodoCompleto && tecnica != Tecnica.normal) ..._emQuaisSeries(tecnica, p),
      ],
    );
  }

  List<Widget> _parametrosDaTecnica(Tecnica tecnica, ParametrosDoMetodo p) => switch (tecnica) {
    Tecnica.dropset => [
      _parametro<int>(prescriptionMetodoQuedas, {1: '1', 2: '2', 3: '3'}, p.quedas,
          (v) => _mudarParametros(p.copyWith(quedas: v))),
      _parametro<int>(prescriptionMetodoReducao, {10: '−10%', 20: '−20%', 30: '−30%'}, p.reducaoPct,
          (v) => _mudarParametros(p.copyWith(reducaoPct: v))),
    ],
    Tecnica.restpause => [
      _parametro<int>(prescriptionMetodoPausa, {10: '10 s', 15: '15 s', 20: '20 s'}, p.pausaS,
          (v) => _mudarParametros(p.copyWith(pausaS: v))),
      _parametro<int>(prescriptionMetodoMiniSeries, {1: '1', 2: '2', 3: '3'}, p.miniSeries,
          (v) => _mudarParametros(p.copyWith(miniSeries: v))),
    ],
    Tecnica.pico => [
      _parametro<int>(prescriptionMetodoSegurarNoPico, {1: '1 s', 2: '2 s', 3: '3 s', 5: '5 s'},
          _opcao(p.segundos, const [1, 2, 3, 5], 2), (v) => _mudarParametros(p.copyWith(segundos: v))),
    ],
    Tecnica.excentrica => [
      _parametro<int>(prescriptionMetodoDescerEm, {3: '3 s', 4: '4 s', 5: '5 s'},
          _opcao(p.segundos, const [3, 4, 5], 4), (v) => _mudarParametros(p.copyWith(segundos: v))),
    ],
    Tecnica.isometria => [
      _parametro<int>(prescriptionMetodoPararPor, {3: '3 s', 5: '5 s', 10: '10 s'},
          _opcao(p.segundos, const [3, 5, 10], 5), (v) => _mudarParametros(p.copyWith(segundos: v))),
    ],
    Tecnica.parciais => [
      _parametro<int>(prescriptionMetodoParciais, {5: '5', 8: '8', 10: '10'},
          _opcao(p.parciais, const [5, 8, 10], 8), (v) => _mudarParametros(p.copyWith(parciais: v))),
    ],
    Tecnica.normal => const [],
  };

  /// O valor salvo se ele está nas opções desta técnica; senão o padrão dela.
  static int _opcao(int valor, List<int> opcoes, int padrao) => opcoes.contains(valor) ? valor : padrao;

  List<Widget> _emQuaisSeries(Tecnica tecnica, ParametrosDoMetodo p) {
    final validas = _validas;
    final emQuais = p.emQuaisPara(tecnica);
    return [
      _parametro<EmQuaisSeries>(
        prescriptionMetodoEmQuais,
        {
          EmQuaisSeries.ultima: prescriptionMetodoSoAUltima,
          EmQuaisSeries.todas: prescriptionMetodoTodasValidas,
          EmQuaisSeries.escolher: prescriptionMetodoEscolher,
        },
        emQuais,
        (v) => _mudarParametros(p.copyWith(
          emQuais: v,
          // "Escolher" começa com a última marcada.
          escolhidas: v == EmQuaisSeries.escolher && p.escolhidas.isEmpty ? {validas} : null,
        )),
      ),
      if (emQuais == EmQuaisSeries.escolher)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.groupPadH, 0, FxSettingsLayout.groupPadH, TokensStrip.s2),
          child: Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              for (var i = 1; i <= validas; i++)
                FilterChip(
                  label: Text('Válida $i'),
                  selected: p.escolhidas.contains(i),
                  onSelected: widget.enabled
                      ? (marcar) => _mudarParametros(p.copyWith(
                            escolhidas: marcar ? {...p.escolhidas, i} : ({...p.escolhidas}..remove(i)),
                          ))
                      : null,
                ),
            ],
          ),
        ),
    ];
  }
}
