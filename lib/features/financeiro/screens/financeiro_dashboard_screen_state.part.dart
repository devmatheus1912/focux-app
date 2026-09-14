part of 'financeiro_dashboard_screen.dart';

class _FinanceiroDashboardScreenState
    extends ConsumerState<FinanceiroDashboardScreen> {
  FinanceiroDashboard? _data;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

    final d = _data!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zeroData =
        !d.receitaMes.isPositive &&
        d.vencimentosProximos.isEmpty &&
        d.topAlunos.isEmpty;

    if (zeroData) {
      return fxScreenA11yScope(
        label: 'Dashboard financeiro',
        child: FxEmptyState(
          icon: 'coin',
          title: 'Sem dados financeiros',
          // Nunca ecoar BE zeroCta "Abrir financeiro" aqui — já estamos no hub.
          subtitle: 'Lance a primeira mensalidade para ver o dashboard.',
          action: FxEmptyAction(
            label: 'Nova mensalidade',
            onTap:
                () => FinanceiroHubScope.maybeOf(
                  context,
                )?.openNovaMensalidade(source: 'empty_resumo'),
          ),
        ),
      );
    }

    return fxScreenA11yScope(
      label: 'Dashboard financeiro',
      child: RefreshIndicator(
        onRefresh: () {
          AnalyticsService.instance.track(ProductEvents.financeiroRefreshed);
          return _load(force: true);
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                0,
              ),
              child: SmartPricingCard(),
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            _FinanceiroKpiGroup(data: d),
            const SizedBox(height: FxSettingsLayout.groupGap),
            _EvolucaoChart(items: d.evolucaoMensal, isDark: isDark),
            if (d.vencimentosProximos.isNotEmpty) ...[
              const SizedBox(height: FxSettingsLayout.groupGap),
              _FinanceiroVencimentosGroup(items: d.vencimentosProximos),
            ],
            if (d.topAlunos.isNotEmpty) ...[
              const SizedBox(height: FxSettingsLayout.groupGap),
              _FinanceiroTopAlunosGroup(items: d.topAlunos),
            ],
          ],
        ),
      ),
    );
  }
}
