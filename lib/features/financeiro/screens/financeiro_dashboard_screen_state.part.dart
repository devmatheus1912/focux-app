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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final dashboard = await repo.dashboard();
      if (mounted) {
        setState(() {
          _data = dashboard;
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
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: FxLoading(strokeWidth: 2.5),
        ),
      );
    }
    if (_data == null) {
      final isDarkErr = Theme.of(context).brightness == Brightness.dark;
      final inkErr = isDarkErr ? EagleTokens.darkInk : TokensStrip.textPrimary;
      final muteErr =
          isDarkErr ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
      final primaryErr = Theme.of(context).colorScheme.primary;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: isDarkErr ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: EagleTokens.bad,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Erro ao carregar',
                style: AppTypography.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: inkErr,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _erro ?? 'Verifique sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muteErr, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: TokensStrip.s4),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(FocuxMicrocopy.tentarNovamente),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryErr,
                  side: BorderSide(color: primaryErr.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        onRefresh: _load,
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
