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
      return const FxLoading();
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
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);

    return fxScreenA11yScope(
      label: 'Dashboard financeiro',
      child: RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SmartPricingCard(),
            ),
            const SizedBox(height: TokensStrip.s4),
            // Hero — ring with received amount
            _HeroRing(data: d, isDark: isDark),

            // Tri-grid metrics
            _TriGrid(data: d, isDark: isDark),

            // Evolução — bar chart
            _EvolucaoChart(items: d.evolucaoMensal, isDark: isDark),

            // Vencimentos próximos
            if (d.vencimentosProximos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 22, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vencimentos',
                      style: AppTypography.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? EagleTokens.darkInk
                                : TokensStrip.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Cobrar todos →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children:
                      d.vencimentosProximos
                          .map((v) => _VencimentoRow(item: v, isDark: isDark))
                          .toList(),
                ),
              ),
            ],

            // Top alunos
            if (d.topAlunos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 22, 20, 10),
                child: Text(
                  'Top alunos · acumulado',
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: fxListCardDecoration(
                    context,
                    accent: primary,
                    radius: 20,
                  ),
                  child: Column(
                    children:
                        d.topAlunos.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final t = e.value;
                          final isLast = rank == d.topAlunos.length;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border:
                                  isLast
                                      ? null
                                      : Border(
                                        bottom: BorderSide(
                                          color:
                                              isDark
                                                  ? EagleTokens.darkLine
                                                  : TokensStrip.borderDefault,
                                          width: 0.5,
                                        ),
                                      ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? primary.withValues(alpha: 0.18)
                                            : primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? primaryDeep : primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t.alunoNome.isNotEmpty
                                        ? t.alunoNome[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.alunoNome,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? EagleTokens.darkInk
                                              : TokensStrip.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'R\$ ${(t.totalPago / 1000).toStringAsFixed(1)}k',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? EagleTokens.darkInk
                                            : TokensStrip.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
