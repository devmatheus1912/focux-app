part of 'anamnese_aluno_screen.dart';

extension on _AnamneseAlunoScreenState {
  /// Ficha enviada: leitura por seção, com "Editar" em cada uma.
  Widget _corpoResumo(S s, Anamnese a) {
    final secoes = [
      (
        s.anamneseAlunoEtapaSaudeGeral,
        AnamneseEtapa.saudeGeral,
        [(s.anamneseAlunoRespostasSim, '${_parq.values.where((v) => v == true).length}')],
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
          (s.anamneseAlunoTabagismo, _tabagismoCtrl.text),
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
            title: s.anamneseAlunoEnviadaTitulo,
            body: s.anamneseAlunoEnviadaTexto,
            tone: a.isPrecisaAtestado ? FxBannerTone.warn : FxBannerTone.success,
          ),
          for (final (titulo, etapa, linhas) in secoes) ...[
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              header: titulo,
              children: [
                for (final (rotulo, valor) in linhas)
                  if (valor.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: TokensStrip.s1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rotulo,
                            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                          ),
                          Text(
                            valor.trim(),
                            style: FocuxHubTypography.body(color: chrome.ink),
                          ),
                        ],
                      ),
                    ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FxTonalButton(
                    label: s.anamneseAlunoEditar,
                    compact: true,
                    onPressed: () {
                      setState(() => _editando = true);
                      _irPara(etapa);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
