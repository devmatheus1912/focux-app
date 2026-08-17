part of 'relatorio_screen.dart';

class _RelatorioScreenState extends ConsumerState<RelatorioScreen> {
  int _dias = 30;
  DateTimeRange? _rangeCustom;
  AderenciaData? _dados;
  ComparativoPeriodo? _comparativo;
  bool _carregando = false;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _escolherPeriodoCustom() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange:
          _rangeCustom ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() => _rangeCustom = range);
      _carregarDados();
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final repo = RelatorioRepository(ref.read(apiClientProvider));
      final home = await repo.getHome(
        widget.alunoId,
        dias: _dias,
        inicio: _rangeCustom?.start,
        fim: _rangeCustom?.end,
      );
      if (mounted) {
        setState(() {
          _dados = home.aderencia;
          _comparativo = home.comparativo;
          _carregando = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _carregando = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    if (_dados == null) return;
    await exportRelatorioPdf(
      alunoNome: widget.alunoNome,
      periodoLabel: relatorioPeriodoLabelPdf(
        dias: _dias,
        rangeCustom:
            _rangeCustom == null
                ? null
                : DateTimeRangePdf(
                  start: _rangeCustom!.start,
                  end: _rangeCustom!.end,
                ),
      ),
      dados: _dados!,
      comparativo: _comparativo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final subtitle =
        freshnessLabel == null
            ? widget.alunoNome
            : '${widget.alunoNome} · $freshnessLabel';

    return fxScreenA11yScope(
      label: 'Relatório — ${widget.alunoNome}',
      child: FxShellScaffold(
        constrainWidth: false,
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Relatório',
          subtitle: subtitle,
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            Semantics(
              label: 'Exportar relatório em PDF',
              button: true,
              child: IconButton(
                tooltip: 'Exportar PDF',
                onPressed: _dados != null ? _exportarPdf : null,
                icon: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: chrome.ink.withValues(alpha: 0.75),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: RefreshIndicator(
            onRefresh: _carregarDados,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TokensStrip.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SeletorPeriodo(
                    diasSelecionado: _dias,
                    rangeCustom: _rangeCustom,
                    onChanged: (dias) {
                      setState(() {
                        _dias = dias;
                        _rangeCustom = null;
                      });
                      _carregarDados();
                    },
                    onCustom: _escolherPeriodoCustom,
                  ),
                  const SizedBox(height: 20),
                  if (_carregando)
                    const SkeletonList(count: 4)
                  else if (_erro != null)
                    SizedBox(
                      height: 280,
                      child: FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: theme.colorScheme.primary,
                        message: _erro!,
                        onRetry: _carregarDados,
                        title: 'Não conseguimos carregar o relatório',
                      ),
                    )
                  else if (_dados != null && _dados!.treinosTotal == 0)
                    FxEmptyState(
                      icon: 'article',
                      title: 'Sem dados neste período',
                      subtitle:
                          'Quando ${satelliteFirstName(widget.alunoNome)} concluir treinos, o relatório aparece aqui.',
                      action: FxEmptyAction(
                        label: 'Atualizar',
                        onTap: _carregarDados,
                      ),
                    )
                  else if (_dados != null) ...[
                    _CardAderencia(
                      dados: _dados!,
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    if (_comparativo != null) ...[
                      _CardComparativo(comparativo: _comparativo!),
                      const SizedBox(height: TokensStrip.s4),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _CardInfo(
                            icone: Icons.check_circle_outline,
                            titulo: 'Treinos Concluídos',
                            valor:
                                '${_dados!.treinosConcluidos} / ${_dados!.treinosTotal}',
                            cor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CardInfo(
                            icone: Icons.calendar_today_outlined,
                            titulo: 'Dias Analisados',
                            valor: '${_dados!.diasAnalisados}',
                            cor: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
