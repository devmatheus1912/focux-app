part of 'churn_dashboard_screen.dart';

extension _ChurnDashboardContent on _ChurnDashboardScreenState {
  Widget _conteudo(BuildContext context, RetencaoHome home) {
    final s = S.of(context);
    final contagem = retencaoContagem(home);
    final chamar = retencaoChamarAgora(home.top3, _base);
    final fila = filaSemAluno(retencaoFiltrar(_base, _nivel), chamar?.alunoId);
    final filtros = mostrarFiltros(contagem);

    String rotuloNivel(RetencaoNivel n) => switch (n) {
      RetencaoNivel.alto => s.retencaoMetAlto,
      RetencaoNivel.atencao => s.retencaoMetAtencao,
      RetencaoNivel.saudavel => s.retencaoMetSaudaveis,
    };

    FxMetric metrica(RetencaoNivel n, {bool alerta = false}) => FxMetric(
      valor: contagem[n]!,
      rotulo: rotuloNivel(n),
      alerta: alerta,
      onTap: contagem[n]! > 0 ? () => setState(() => _nivel = n) : null,
    );

    return FxContentWidthLimiter(
      child: ListView(
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
          const SizedBox(height: TokensStrip.s4),
          DashboardSectionHeader(title: s.retencaoChamarAgora),
          const SizedBox(height: TokensStrip.s2),
          if (chamar == null)
            _SemRiscoAlto(
              titulo: s.retencaoNinguemAlto,
              texto: s.retencaoNinguemAltoTexto,
            )
          else ...[
            FxActionRow(
              titulo: chamar.alunoNome,
              motivo: retencaoSaudeTexto(s, chamar),
              verbo: s.retencaoVerboChamar,
              onTap: () => _abrirChat(chamar),
            ),
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionChip(
                label: s.retencaoMaisAcoes,
                accent: ShellChrome.of(context).mute,
                isDark: ShellChrome.of(context).isDark,
                onPressed: () => _abrirAcoes(chamar),
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s4),
          DashboardSectionHeader(title: s.retencaoFilaTitulo),
          const SizedBox(height: TokensStrip.s2),
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _onBusca,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: FxInputDeco.build(context, s.retencaoBuscar),
          ),
          if (filtros) ...[
            const SizedBox(height: TokensStrip.s2),
            FxChoiceStrip<RetencaoNivel?>(
              itens: [
                FxChoiceItem(value: null, label: s.retencaoFiltroTodos),
                for (final n in RetencaoNivel.values)
                  if (contagem[n]! > 0)
                    FxChoiceItem(value: n, label: rotuloNivel(n)),
              ],
              selecionado: _nivel,
              onSelecionar: (n) => setState(() => _nivel = n),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          if (fila.isEmpty)
            FxEmptyState(
              icon: 'activity',
              title: s.retencaoFilaVazia,
              subtitle: s.retencaoFilaVaziaTexto,
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
          const SizedBox(height: TokensStrip.s4),
          FxSettingsGroup(
            children: [
              FxSettingsTile(
                fxIcon: 'bell',
                label: s.retencaoEntradaHistorico,
                subtitle: s.retencaoEntradaHistoricoSub,
                value: '',
                onTap: () => context.push('/winback'),
              ),
              FxSettingsTile(
                fxIcon: 'repeat',
                label: s.retencaoEntradaCobranca,
                subtitle: s.retencaoEntradaCobrancaSub,
                value: '',
                showDivider: false,
                onTap: () => context.push('/dunning'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
