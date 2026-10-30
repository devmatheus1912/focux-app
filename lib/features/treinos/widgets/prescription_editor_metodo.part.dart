part of 'prescription_editor_sheet.dart';

/// Seção "Método": técnica da série e só os parâmetros dela.
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
          Text(rotulo, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          const SizedBox(height: TokensStrip.s1),
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

  /// Técnica da série e só os parâmetros dela. Combinar (bi-set) é na lista do treino.
  Widget _metodo() {
    final tecnica = _tipoSerie.toUpperCase();
    return FxSettingsGroup(
      header: prescriptionMetodo,
      accent: widget.primary,
      children: [
        _parametro<String>(
          prescriptionMetodo,
          {
            for (final t in Tecnica.values) tecnicaParaApi(t): rotuloDaTecnica(t),
          },
          tecnicaParaApi(tecnicaDe(tecnica)),
          _mudarTecnica,
        ),
        if (tecnica == 'DROPSET') ...[
          _parametro<int>(prescriptionMetodoQuedas, {1: '1', 2: '2', 3: '3'}, _parametros.quedas,
              (v) => _mudarParametros(_parametros.copyWith(quedas: v))),
          _parametro<int>(prescriptionMetodoReducao, {10: '−10%', 20: '−20%', 30: '−30%'}, _parametros.reducaoPct,
              (v) => _mudarParametros(_parametros.copyWith(reducaoPct: v))),
        ],
        if (tecnica == 'RESTPAUSE') ...[
          _parametro<int>(prescriptionMetodoPausa, {10: '10 s', 15: '15 s', 20: '20 s'}, _parametros.pausaS,
              (v) => _mudarParametros(_parametros.copyWith(pausaS: v))),
          _parametro<int>(prescriptionMetodoMiniSeries, {1: '1', 2: '2', 3: '3'}, _parametros.miniSeries,
              (v) => _mudarParametros(_parametros.copyWith(miniSeries: v))),
        ],
        if (tecnica == 'PIRAMIDE')
          _parametro<bool>(
            prescriptionMetodoSentido,
            {true: prescriptionMetodoCrescente, false: prescriptionMetodoDecrescente},
            _parametros.piramideCrescente,
            (v) => _mudarParametros(_parametros.copyWith(piramideCrescente: v)),
          ),
      ],
    );
  }
}
