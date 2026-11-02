part of 'anamnese_aluno_screen.dart';

String _dataCurta(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '';
  String dd(int n) => n.toString().padLeft(2, '0');
  return '${dd(d.day)}/${dd(d.month)}/${d.year}';
}

extension on _AnamneseAlunoScreenState {
  /// Ficha enviada: leitura por seção, com "Editar" em cada uma.
  Widget _corpoResumo(S s, Anamnese a) {
    final secoes = [
      (
        s.anamneseAlunoEtapaSaudeGeral,
        AnamneseEtapa.saudeGeral,
        [
          (
            s.anamneseAlunoRespostasSim,
            _parq.values.any((v) => v == true)
                ? '${_parq.values.where((v) => v == true).length}'
                : s.anamneseAlunoSemRestricao,
          ),
        ],
      ),
      (
        s.anamneseAlunoHistorico,
        AnamneseEtapa.historico,
        [
          (s.anamneseAlunoCondicoes, _historicoCtrl.text),
          (s.anamneseAlunoCirurgias, _cirurgiasCtrl.text),
          (s.anamneseAlunoDores, _doresCtrl.text),
          (s.anamneseAlunoLesoes, _lesoesCtrl.text),
          (s.anamneseAlunoMedicamentos, _medicCtrl.text),
          (s.anamneseAlunoAlergias, _alergiasCtrl.text),
        ],
      ),
      (
        s.anamneseAlunoHabitos,
        AnamneseEtapa.habitos,
        [
          if (_sonoHoras != null)
            (s.anamneseAlunoHorasSono, anamneseSonoHorasLabel(_sonoHoras)),
          (s.anamneseAlunoQualidadeSono, _qualidadeSonoCtrl.text),
          (s.anamneseAlunoEstresse, _estresseCtrl.text),
          (s.anamneseAlunoTabagismo, anamneseValorLegivel(_tabagismoCtrl.text)),
          (s.anamneseAlunoAlcool, _alcoolCtrl.text),
        ],
      ),
      (
        s.anamneseAlunoObjetivos,
        AnamneseEtapa.objetivos,
        [
          (s.anamneseAlunoObjetivo, _objetivoCtrl.text),
          if (_dispSemanal != null)
            (s.anamneseAlunoDias, anamneseDisponibilidadeLabel(_dispSemanal!)),
          (s.anamneseAlunoPreferencias, _prefTreinoCtrl.text),
        ],
      ),
    ];
    final chrome = ShellChrome.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          24,
        ),
        children: [
          FxStatusBanner(
            title:
                a.isRevisada
                    ? s.anamneseAlunoRevisadaTitulo
                    : s.anamneseAlunoEnviadaTitulo,
            body:
                a.isRevisada
                    ? s.anamneseAlunoRevisadaTexto(_dataCurta(a.revisadaEm))
                    : s.anamneseAlunoEnviadaTexto,
            tone: FxBannerTone.success,
          ),
          for (final (titulo, etapa, linhas) in secoes) ...[
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              header: titulo,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          linhas.any((l) => l.$2.trim().isNotEmpty)
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final (rotulo, valor) in linhas)
                                    if (valor.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: TokensStrip.s1,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rotulo,
                                              style: FocuxHubTypography.bodyMuted(
                                                color: chrome.mute,
                                              ),
                                            ),
                                            Text(
                                              valor.trim(),
                                              style: FocuxHubTypography.body(
                                                color: chrome.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ],
                              )
                              : Text(
                                s.anamneseAlunoNadaInformado,
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                    ),
                    IconButton(
                      tooltip: s.anamneseAlunoEditar,
                      icon: Icon(Icons.edit_outlined, color: chrome.mute),
                      onPressed: () {
                        setState(() => _editando = true);
                        _irPara(etapa);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
