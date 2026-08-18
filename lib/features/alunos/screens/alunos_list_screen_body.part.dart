part of 'alunos_list_screen.dart';

extension AlunosListScreenBody on _AlunosListScreenState {
  Widget _buildAlunosHomeData(AlunosHomeBundle home) {
              final chrome = ShellChrome.of(context);
              final isDark = chrome.isDark;
              final primary = Theme.of(context).colorScheme.primary;
              final ink = chrome.ink;
              final mute = chrome.mute;
              final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
              final alunos = [
                ...home.alunos,
                ...ref.watch(alunosHomeTailProvider).alunos,
              ];
              final stats = home.stats;
              final diasLimite = home.alertasConfig.diasSemTreino;
              final filtrados = alunos;
              final ativosCount = stats.totalAtivos;
              final inadCount = stats.totalInadimplentes;
              final riscoCount = stats.totalRiscoAlto;
              final contatoCount = stats.totalContatoHoje;
              final novosCount = stats.totalConvites;
              final showTriageBanner =
                  !_modoSelecao &&
                  _filtro == AlunoFiltro.todos &&
                  contatoCount > 0;
              final headerOps =
                  _modoSelecao
                      ? _selectionSummary()
                      : (showTriageBanner
                          ? null
                          : (novosCount > 0
                              ? '$novosCount convites'
                              : null));
              final showHeaderBack = !_modoSelecao && _hasActiveFilter;
              final headerBackFromDashboard = _hasDeepLinkFiltro(context);
              final triageContextActive = showTriageBanner || contatoCount > 0;
              final listBottomGap = AlunosLayout.listBottomGap(context);
              final tail = ref.watch(alunosHomeTailProvider);

              return SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAlunosListHeader(
                      totalCount: stats.total,
                      contatoCount: contatoCount,
                      ativosCount: ativosCount,
                      inadCount: inadCount,
                      riscoCount: riscoCount,
                      novosCount: novosCount,
                      headerOps: headerOps,
                      showHeaderBack: showHeaderBack,
                      headerBackFromDashboard: headerBackFromDashboard,
                      freshnessLabel: freshnessLabel,
                      chrome: chrome,
                      isDark: isDark,
                      primary: primary,
                      ink: ink,
                      mute: mute,
                    ),

                    if (!_modoSelecao &&
                        _filtro == AlunoFiltro.todos &&
                        contatoCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AlunosLayout.screenPadding,
                          0,
                          AlunosLayout.screenPadding,
                          8,
                        ),
                        child: _AlunosTriageBanner(
                          count: contatoCount,
                          isDark: isDark,
                          title: '$contatoCount precisam de contato hoje',
                          subtitle:
                              'Risco, inadimplência ou $diasLimite+ dias sem treino',
                          onTap: () => _setFiltro(AlunoFiltro.contatoHoje),
                        ),
                      )
                    else if (!_modoSelecao &&
                        _filtro == AlunoFiltro.todos &&
                        riscoCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AlunosLayout.screenPadding,
                          0,
                          AlunosLayout.screenPadding,
                          8,
                        ),
                        child: _AlunosTriageBanner(
                          count: riscoCount,
                          isDark: isDark,
                          title:
                              '$riscoCount aluno${riscoCount == 1 ? '' : 's'} em risco',
                          subtitle:
                              'Priorize contato e retomada de treino hoje',
                          onTap: () => _setFiltro(AlunoFiltro.risco),
                        ),
                      ),

                    // List
                    Expanded(
                      child:
                          filtrados.isEmpty
                              ? _EmptyAlunosState(
                                hasQuery: _query.trim().isNotEmpty,
                                hasActiveFilter: _hasActiveFilter,
                                filtroLabel: _filtroLabel(_filtro),
                                onAdd: _adicionarAluno,
                                onClear:
                                    _query.trim().isEmpty
                                        ? null
                                        : () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                onClearFilter:
                                    _hasActiveFilter
                                        ? () => _setFiltro(AlunoFiltro.todos)
                                        : null,
                              )
                              : RefreshIndicator(
                                onRefresh: _refreshHome,
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (n.metrics.extentAfter < 480 &&
                                        tail.hasNext &&
                                        !tail.loading) {
                                      ref
                                          .read(alunosHomeTailProvider.notifier)
                                          .loadMore(
                                            query: ref.read(
                                              alunosHomeQueryProvider,
                                            ),
                                            repo: ref.read(
                                              alunoRepositoryProvider,
                                            ),
                                          );
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    left: AlunosLayout.screenPadding,
                                    right: AlunosLayout.screenPadding,
                                    top: 8,
                                    bottom: listBottomGap,
                                  ),
                                  itemCount:
                                      filtrados.length + (tail.hasNext ? 1 : 0),
                                  separatorBuilder:
                                      (_, __) => SizedBox(
                                        height:
                                            _listaCompacta
                                                ? AlunosLayout.listItemGapCompact
                                                : AlunosLayout.listItemGap,
                                      ),
                                  itemBuilder: (context, i) {
                                    if (i >= filtrados.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: FxLoading.sectionShimmer(
                                          context,
                                          height: 22,
                                          showHeader: false,
                                        ),
                                      );
                                    }
                                    final a = filtrados[i];
                                    return FxStaggerItem(
                                      index: i,
                                      child: AlunoListCard(
                                        aluno: a,
                                        modoSelecao: _modoSelecao,
                                        isSelected: _selecionados.contains(
                                          a.id,
                                        ),
                                        onToggle:
                                            () => _toggleSelecionado(a.id),
                                        onLongPress:
                                            _modoSelecao
                                                ? null
                                                : _toggleModoSelecao,
                                        activeFiltro: _filtro,
                                        triageContextActive:
                                            triageContextActive,
                                        diasSemTreinoLimite: diasLimite,
                                        compact: _listaCompacta,
                                      ),
                                    );
                                  },
                                ),
                                ),
                              ),
                    ),

                    // Bottom action bar (seleção)
                    AnimatedContainer(
                      duration:
                          TokensStrip.prefersReducedMotion(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                      height:
                          (_modoSelecao && _selecionados.isNotEmpty) ? null : 0,
                      child:
                          (_modoSelecao && _selecionados.isNotEmpty)
                              ? SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    TokensStrip.s4,
                                    8,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              if (_selecionados.length ==
                                                  filtrados.length) {
                                                _selecionados.clear();
                                              } else {
                                                _selecionados.addAll(
                                                  filtrados.map((a) => a.id),
                                                );
                                              }
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.select_all,
                                            size: 18,
                                          ),
                                          label: Text(
                                            _selecionados.length ==
                                                    filtrados.length
                                                ? 'Desmarcar todos'
                                                : 'Selecionar todos',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color:
                                                  isDark
                                                      ? EagleTokens.darkLine
                                                      : TokensStrip
                                                          .borderDefault,
                                            ),
                                            foregroundColor: ink,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _showBulkActionsSheet,
                                          icon: const Icon(
                                            Icons.bolt_rounded,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Ações (${_selecionados.length})',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
  }
}
