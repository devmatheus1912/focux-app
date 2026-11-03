part of 'churn_dashboard_screen.dart';

extension _ChurnDashboardContent on _ChurnDashboardScreenState {
  Widget _conteudo(BuildContext context, RetencaoHome home) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final contagem = retencaoContagem(home);
    final chamar = _nivel == null ? home.top3 : const <RetencaoAlunoScore>[];
    final fila = filaSem(_base, chamar);
    final variacao = retencaoVariacaoSemanal(home);

    String rotuloNivel(RetencaoNivel n) => switch (n) {
      RetencaoNivel.alto => s.retencaoMetAlto,
      RetencaoNivel.atencao => s.retencaoMetAtencao,
      RetencaoNivel.saudavel => s.retencaoMetSaudaveis,
    };

    FxMetric metrica(RetencaoNivel n, {bool alerta = false}) => FxMetric(
      valor: contagem[n]!,
      rotulo: rotuloNivel(n),
      alerta: alerta,
      onTap: contagem[n]! > 0 ? () => _filtrar(n) : null,
    );

    return FxContentWidthLimiter(
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        children: [
          FxMetricStrip(
            metricas: [
              metrica(RetencaoNivel.alto, alerta: true),
              metrica(RetencaoNivel.atencao),
              metrica(RetencaoNivel.saudavel),
            ],
          ),
          if (variacao != null) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              variacao,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
          if (_nivel != null) ...[
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionChip(
                label: s.retencaoFiltroTodos,
                accent: chrome.mute,
                isDark: chrome.isDark,
                onPressed: () => _filtrar(null),
              ),
            ),
          ] else ...[
            const SizedBox(height: TokensStrip.s4),
            DashboardSectionHeader(title: s.retencaoChamarAgora),
            const SizedBox(height: TokensStrip.s2),
            if (chamar.isEmpty)
              _SemRiscoAlto(texto: s.retencaoNinguemAltoTexto)
            else
              for (final aluno in chamar)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                  child: FxActionRow(
                    titulo: aluno.alunoNome,
                    motivo: retencaoMotivoCurto(aluno) ?? '',
                    verbo: s.retencaoAcaoMensagem,
                    onTap: () => _abrirChat(aluno),
                  ),
                ),
          ],
          const SizedBox(height: TokensStrip.s4),
          DashboardSectionHeader(title: s.retencaoFilaTitulo),
          const SizedBox(height: TokensStrip.s2),
          if (mostrarBusca(home)) ...[
            TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _onBusca,
              onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
              decoration: FxInputDeco.build(context, s.retencaoBuscar),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
          if (fila.isEmpty)
            Text(
              s.retencaoFilaVaziaTexto,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            )
          else
            for (final score in fila)
              _RetencaoTile(
                score: score,
                onAluno: () => _abrirAluno(score),
                onChat: () => _abrirChat(score),
                onMais: () => _abrirAcoes(score),
              ),
          if (_hasNext)
            FxSatelliteListTile(
              title: _carregandoMais ? 'Carregando…' : s.retencaoCarregarMais,
              titleCase: false,
              onTap: _carregandoMais ? null : _carregarMais,
            ),
        ],
      ),
    );
  }
}
