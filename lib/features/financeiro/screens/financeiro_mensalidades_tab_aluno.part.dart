part of 'financeiro_mensalidades_tab.dart';

/// Financeiro de um aluno só: resumo, filtros à esquerda, um grupo com uma
/// linha por mês (sem o nome, a tela já é dele) e os meses sem cobrança.
extension FinanceiroMensalidadesTabAluno on _FinanceiroMensalidadesTabState {
  Widget _buildDoAluno(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    final hoje = DateTime.now();
    final aluno = ref.watch(alunoProvider(widget.initialAlunoId!)).value;
    final ativo = aluno == null || aluno.status.toUpperCase() == 'ATIVO';
    final linhas = financeiroLinhasDoAluno(
      _items,
      hoje: hoje,
      comMesesVazios: _filtro == MensalidadeFiltro.todas && ativo,
    );
    final todas = _todasDoAluno;
    final resumo = financeiroResumoDoAluno(
      todas ?? (_homeItems.isEmpty ? _items : _homeItems),
      hoje: hoje,
      parcial: todas == null && _hasMore,
    );

    return fxScreenA11yScope(
      label: 'Mensalidades',
      child: Column(
        children: [
          Expanded(
            child:
                _loading
                    ? _buildMensalidadesLoading(context)
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: () => _load(force: true),
                    )
                    : RefreshIndicator(
                      onRefresh: _onPullRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s3,
                          FxSettingsLayout.pageInset,
                          24,
                        ),
                        children: [
                          if (_items.isNotEmpty || _filtro != MensalidadeFiltro.todas)
                            FxSettingsGroup(
                              children: [
                                FxSettingsTile(
                                  icon:
                                      resumo.alerta
                                          ? FxIcons.alerta
                                          : FxIcons.dinheiro,
                                  label: resumo.texto,
                                  value: '',
                                  showDivider: false,
                                  accent: resumo.alerta ? alerta : null,
                                ),
                              ],
                            ),
                          const SizedBox(height: TokensStrip.s3),
                          // Filtros alinhados à esquerda, em linha rolável.
                          FxChoiceStrip<MensalidadeFiltro>(
                            itens: [
                              for (final f in MensalidadeFiltro.values)
                                FxChoiceItem(
                                  value: f,
                                  label: mensalidadeFiltroLabel(f, S.of(context)),
                                ),
                            ],
                            selecionado: _filtro,
                            onSelecionar: _trocarFiltro,
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          if (linhas.isEmpty)
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.4,
                              child: _buildMensalidadesEmpty(context),
                            )
                          else
                            Container(
                              decoration: fxListCardDecoration(context),
                              child: Column(
                                children: [
                                  for (final (i, linha) in linhas.indexed) ...[
                                    if (i > 0)
                                      Divider(height: 1, color: chrome.line),
                                    switch (linha) {
                                      LinhaCobranca(:final mensalidade) =>
                                        _linhaCobrancaDoAluno(
                                          mensalidade,
                                          chrome: chrome,
                                          primary: primary,
                                          alerta: alerta,
                                        ),
                                      LinhaMesSemCobranca(:final mes) =>
                                        _linhaMesVazio(mes, chrome, primary),
                                    },
                                  ],
                                ],
                              ),
                            ),
                          if (_hasMore) ...[
                            const SizedBox(height: TokensStrip.s3),
                            FxTonalButton(
                              label:
                                  _carregandoMais
                                      ? 'Carregando…'
                                      : 'Carregar mais',
                              expanded: true,
                              onPressed: _carregandoMais ? null : _carregarMais,
                            ),
                          ],
                        ],
                      ),
                    ),
          ),
          if (_modoSelecao)
            FxFormStickyBar(
              child: Row(
                children: [
                  Expanded(
                    child: FxTonalButton(
                      label: 'Cancelar',
                      expanded: true,
                      onPressed: _sairModoLote,
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: FxLiquidPrimaryButton(
                      label: financeiroListaToolLabel(
                        FinanceiroListaToolId.marcarLote,
                        modoSelecao: true,
                        selecionados: _selecionados.length,
                      ),
                      onPressed:
                          _selecionados.isEmpty ? null : _confirmarLotePago,
                    ),
                  ),
                ],
              ),
            )
          else
            FxFormStickyBar(
              child: FxLiquidPrimaryButton(
                label: 'Nova mensalidade',
                icon: FxIcons.adicionar,
                onPressed: () {
                  FxKeyboardDismissScope.dismiss();
                  _abrirFormularioNovaMensalidade();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _linhaCobrancaDoAluno(
    Mensalidade item, {
    required ShellPalette chrome,
    required Color primary,
    required Color alerta,
  }) {
    final overdue = item.status == 'ATRASADO';
    final cancelada = item.status == 'CANCELADO';
    final aberto = financeiroStatusAberto(item.status);
    final selecionado = _selecionados.contains(item.id);
    final cor = overdue ? alerta : (cancelada ? chrome.mute : primary);
    return InkWell(
      onTap: () => _modoSelecao ? _toggleLote(item) : _abrirAcoes(item),
      onLongPress:
          aberto
              ? () {
                if (!_modoSelecao) _entrarModoLote();
                _toggleLote(item);
              }
              : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s3,
        ),
        child: Row(
          children: [
            Icon(
              _modoSelecao && selecionado
                  ? FxIcons.concluidoAtivo
                  : _modoSelecao
                  ? FxIcons.circulo
                  : overdue
                  ? FxIcons.alerta
                  : item.status == 'PAGO'
                  ? FxIcons.concluido
                  : cancelada
                  ? FxIcons.fechar
                  : FxIcons.relogio,
              size: 20,
              color: cor,
            ),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    financeiroMensalidadeTitulo(item),
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    financeiroSituacaoDoMes(item),
                    style: FocuxHubTypography.bodyMuted(
                      color: overdue ? alerta : chrome.mute,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.valor.formatCobranca(),
              style: FocuxHubTypography.cardTitle(
                color: cancelada ? chrome.mute : chrome.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }

  /// "Outubro 2026 · sem cobrança" com "Lançar" (abre a nova já no mês).
  Widget _linhaMesVazio(DateTime mes, ShellPalette chrome, Color primary) {
    final titulo = financeiroMesTitulo(mes.month, mes.year);
    return Semantics(
      container: true,
      label: '$titulo, sem cobrança',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s3,
          TokensStrip.s2,
          TokensStrip.s2,
          TokensStrip.s2,
        ),
        child: Row(
          children: [
            Icon(FxIcons.circulo, size: 20, color: chrome.mute),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Text(
                '$titulo · sem cobrança',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
            FxTonalButton(
              label: 'Lançar',
              compact: true,
              onPressed: () => _abrirFormularioNovaMensalidade(mesPedido: mes),
            ),
          ],
        ),
      ),
    );
  }
}
