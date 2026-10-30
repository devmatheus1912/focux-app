part of 'financeiro_resultados_screen.dart';

class _FinanceiroResultadosScreenState
    extends ConsumerState<FinanceiroResultadosScreen> {
  late int _ano;
  late int _mes;
  FinanceiroDashboard? _data;
  ResumoMensal? _outroMes;
  BusinessSnapshot? _coorte;
  bool _loading = true;
  bool _loadingOutroMes = false;
  bool _detalhesAbertos = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    _load();
  }

  bool get _mesAtual => resultadosEhMesAtual(_ano, _mes, DateTime.now());

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) ref.invalidate(financeiroHomeProvider);
      final home = await ref.read(financeiroHomeProvider.future);
      if (mounted) {
        setState(() {
          _data = home.dashboard;
          _loading = false;
        });
      }
      unawaited(_carregarCoorte());
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _data = null;
          _loading = false;
        });
      }
    }
  }

  /// A coorte vem de `/relatorio/business` (plano com relatórios). Sem acesso
  /// ou com erro, a seção Detalhes simplesmente não existe.
  Future<void> _carregarCoorte() async {
    try {
      final s = await BusinessRepository(ref.read(apiClientProvider)).snapshot();
      if (mounted) setState(() => _coorte = s);
    } catch (_) {
      if (mounted) setState(() => _coorte = null);
    }
  }

  Future<void> _carregarOutroMes() async {
    setState(() {
      _loadingOutroMes = true;
      _outroMes = null;
    });
    try {
      final r = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).resumoMensal(_ano, _mes);
      if (mounted) {
        setState(() {
          _outroMes = r;
          _loadingOutroMes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loadingOutroMes = false;
        });
      }
    }
  }

  Future<void> _abrirMes() async {
    final s = S.of(context);
    final ops = resultadosMesOpcoes(DateTime.now());
    final selected = FinanceiroMesOpcao(ano: _ano, mes: _mes).key;
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: s.resultadosSemMes,
      selected: selected,
      items: [
        for (final o in ops)
          FxInsetPickerSheetItem(value: o.key, label: o.label),
      ],
    );
    if (!mounted || picked == null || picked == selected) return;
    final match = ops.where((o) => o.key == picked).firstOrNull;
    if (match != null) await _irParaMes(match.ano, match.mes);
  }

  Future<void> _irParaMes(int ano, int mes) async {
    if (resultadosMesFuturo(ano, mes, DateTime.now())) return;
    setState(() {
      _ano = ano;
      _mes = mes;
      _erro = null;
    });
    if (!_mesAtual) await _carregarOutroMes();
  }

  void _andarMes(int delta) {
    final d = DateTime(_ano, _mes + delta);
    _irParaMes(d.year, d.month);
  }

  void _abrirLista(MensalidadeFiltro filtro) {
    final scope = FinanceiroHubScope.maybeOf(context);
    if (scope != null) {
      scope.openFiltro(filtro);
    } else {
      context.push('/financeiro');
    }
  }

  void _explicar(String titulo, String texto) {
    showFxHelpSheet(
      context,
      title: titulo,
      subtitle: S.of(context).resultadosComoLer,
      tips: [FxHelpTip(S.of(context).resultadosComoLer, texto)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(TokensStrip.s4),
        child: SkeletonList(count: 5),
      );
    }
    if (_data == null) {
      return DashboardErrorState(
        chromeOnDark: Theme.of(context).brightness == Brightness.dark,
        primary: Theme.of(context).colorScheme.primary,
        message: _erro ?? 'Verifique sua conexão e tente novamente.',
        onRetry: () => _load(force: true),
      );
    }

    final s = S.of(context);
    final d = _data!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final home = ref.watch(financeiroHomeProvider).value;
    final resumo = _mesAtual ? home?.resumoMesAtual : _outroMes;
    final mesVazio =
        resumo == null ||
        (resumo.totalPrevisto.isZero && resumo.totalRecebido.isZero);
    final zeroData =
        mesVazio &&
        (!_mesAtual ||
            (!d.receitaMes.isPositive &&
                d.vencimentosProximos.isEmpty &&
                d.topAlunos.isEmpty));
    final titulo = financeiroMesTitulo(_mes, _ano);
    final variacao = resultadosVariacaoPct(d.evolucaoMensal, _ano, _mes);

    return fxScreenA11yScope(
      label: 'Resultados do financeiro',
      child: RefreshIndicator(
        onRefresh: () {
          AnalyticsService.instance.track(ProductEvents.financeiroRefreshed);
          return _load(force: true);
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: TokensStrip.s6),
          children: [
            _SeletorDeMes(
              rotulo: titulo,
              onTap: _abrirMes,
              onAnterior: () => _andarMes(-1),
              onProximo: _mesAtual ? null : () => _andarMes(1),
            ),
            if (_loadingOutroMes)
              const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 3),
              )
            else if (!_mesAtual && _erro != null)
              DashboardErrorState(
                chromeOnDark: isDark,
                primary: Theme.of(context).colorScheme.primary,
                message: _erro!,
                onRetry: _carregarOutroMes,
              )
            else if (zeroData)
              Padding(
                padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
                child: FxEmptyState(
                  icon: 'coin',
                  title: _mesAtual ? s.resultadosVazioTitulo : s.resultadosVazioMes(titulo),
                  subtitle: _mesAtual ? s.resultadosVazioTexto : null,
                  action: _mesAtual
                      ? FxEmptyAction(
                        label: 'Nova mensalidade',
                        onTap: () => FinanceiroHubScope.maybeOf(
                          context,
                        )?.openNovaMensalidade(source: 'resultados_empty'),
                      )
                      : null,
                ),
              )
            else ...[
              if (resumo != null) ...[
                _BlocoQuantoEntrou(resumo: resumo, variacaoPct: variacao),
                const SizedBox(height: TokensStrip.s3),
                _BlocoQuemAtrasa(
                  resumo: resumo,
                  onTap: () => _abrirLista(MensalidadeFiltro.atrasadas),
                ),
              ],
              if (d.evolucaoMensal.isNotEmpty) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                _EvolucaoChart(
                  items: d.evolucaoMensal,
                  isDark: isDark,
                  ano: _ano,
                  mes: _mes,
                  onMes: _irParaMes,
                ),
              ],
              if (_mesAtual && d.vencimentosProximos.isNotEmpty) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                _FinanceiroVencimentosGroup(items: d.vencimentosProximos),
              ],
              if (_mesAtual && d.topAlunos.isNotEmpty) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                _FinanceiroTopAlunosGroup(items: d.topAlunos),
              ],
              if (_mesAtual) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.pageInset,
                  ),
                  child: DashboardSectionHeader(title: s.resultadosSecaoPreco),
                ),
                const SizedBox(height: TokensStrip.s2),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.pageInset,
                  ),
                  child: SmartPricingCard(),
                ),
              ],
              if (_mesAtual && _coorte != null) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                _SecaoDetalhes(
                  coorte: _coorte!,
                  abertos: _detalhesAbertos,
                  onAlternar: () =>
                      setState(() => _detalhesAbertos = !_detalhesAbertos),
                  onExplicar: _explicar,
                  isDark: isDark,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
