part of 'alunos_list_screen.dart';

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  AlunoFiltro _filtro = AlunoFiltro.todos;
  AlunoOrdenacao _ordenacao = AlunoOrdenacao.prioridade;
  bool _modoSelecao = false;
  final Set<int> _selecionados = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  Timer? _searchDebounce;
  bool _helpDeepLinkApplied = false;
  bool _ignoredDeepLinkFiltro = false;
  bool _listaCompacta = true;
  DateTime? _fetchedAt;
  AlunosHomeBundle? _displayHome;
  bool _listRefreshing = false;
  bool _operacaoWarmScheduled = false;
  final Map<AlunoFiltro, GlobalKey> _chipKeys = {
    for (final filtro in AlunoFiltro.values) filtro: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _filtro = widget.initialFiltro;
    _loadListPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncHomeQuery();
      _scrollChipIntoView(_filtro);
      _maybeOpenHelpFromDeepLink();
      AnalyticsService.instance.track(
        ProductEvents.alunosViewed,
        props: {'filtro': _filtro.name, 'compact': _listaCompacta},
      );
    });
  }

  Future<void> _loadListPreferences() async {
    final prefs = await AlunoListPreferencesStore.load();
    if (mounted) setState(() => _listaCompacta = prefs.compact);
  }

  @override
  void didUpdateWidget(covariant AlunosListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiltro != widget.initialFiltro) {
      setState(() {
        _filtro = widget.initialFiltro;
        _ignoredDeepLinkFiltro = false;
      });
      _syncHomeQuery();
      _scrollChipIntoView(_filtro);
    }
  }

  bool _hasDeepLinkFiltro(BuildContext context) {
    if (_ignoredDeepLinkFiltro) return false;
    return GoRouterState.of(
          context,
        ).uri.queryParameters.containsKey('filtro') ||
        widget.initialFiltro != AlunoFiltro.todos;
  }

  void _handleHeaderBack() {
    HapticFeedback.selectionClick();
    final fromDashboard = _hasDeepLinkFiltro(context);

    setState(() {
      _filtro = AlunoFiltro.todos;
      _ignoredDeepLinkFiltro = true;
    });
    _syncHomeQuery();
    _scrollChipIntoView(_filtro);

    if (!fromDashboard) return;

    safePopOrGo(context, '/dashboard/personal');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleModoSelecao() {
    HapticFeedback.mediumImpact();
    setState(() {
      _modoSelecao = !_modoSelecao;
      _selecionados.clear();
    });
  }

  Future<void> _adicionarAluno() async {
    HapticFeedback.selectionClick();
    final home = ref.read(alunosHomeProvider).valueOrNull;
    final plano =
        home?.planoFeatures ?? ref.read(planoFeaturesProvider).valueOrNull;
    final limite = plano?.limiteAlunos;
    final total = home?.stats.total ?? 0;
    if (limite != null && limite > 0 && total >= limite) {
      await UpgradePromptSheet.show(
        context: context,
        featureName: 'Mais vagas de alunos',
        capability: 'alunos',
      );
      return;
    }
    AnalyticsService.instance.track(
      ProductEvents.alunosAddTapped,
      props: {'feature': 'alunos'},
    );
    final criado = await context.push<bool>('/alunos/novo');
    if (criado == true) {
      invalidateAlunosCaches(ref);
    }
  }

  void _setFiltro(AlunoFiltro filtro, {bool track = true}) {
    final next =
        filtro == AlunoFiltro.inadimplentes && !_temFinanceiro
            ? AlunoFiltro.todos
            : filtro;
    final query = AlunosHomeQuery(
      q: _query,
      filtro: next,
      ordenacao: _ordenacao,
    );
    final cached = AlunosHomeClientCache.getIfFresh(query);
    setState(() {
      _filtro = next;
      _listRefreshing = cached == null;
      if (cached != null) _displayHome = cached;
    });
    _syncHomeQuery();
    _scrollChipIntoView(next);
    if (track) {
      AnalyticsService.instance.track(
        ProductEvents.alunosFilterChanged,
        props: {'filtro': next.name},
      );
    }
  }

  void _scrollChipIntoView(AlunoFiltro filtro) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[filtro]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.12,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _setOrdenacao(AlunoOrdenacao ordenacao) {
    final query = AlunosHomeQuery(
      q: _query,
      filtro: _filtro,
      ordenacao: ordenacao,
    );
    final cached = AlunosHomeClientCache.getIfFresh(query);
    setState(() {
      _ordenacao = ordenacao;
      _listRefreshing = cached == null;
      if (cached != null) _displayHome = cached;
    });
    _syncHomeQuery();
  }

  void _syncHomeQuery() {
    ref.read(alunosHomeQueryProvider.notifier).state = AlunosHomeQuery(
      q: _query,
      filtro: _filtro,
      ordenacao: _ordenacao,
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = AlunosHomeQuery(
        q: _query,
        filtro: _filtro,
        ordenacao: _ordenacao,
      );
      final cached = AlunosHomeClientCache.getIfFresh(query);
      setState(() {
        _listRefreshing = cached == null;
        if (cached != null) _displayHome = cached;
      });
      _syncHomeQuery();
      AnalyticsService.instance.track(ProductEvents.alunosSearchUsed);
    });
  }

  void _maybeOpenHelpFromDeepLink() {
    if (_helpDeepLinkApplied) return;
    final sheet = GoRouterState.of(context).uri.queryParameters['sheet'];
    if (sheet != 'help') return;
    _helpDeepLinkApplied = true;
    showAlunosListHelpSheet(context);
    AnalyticsService.instance.track(ProductEvents.alunosHelpOpened);
  }

  Future<void> _openHelp() async {
    AnalyticsService.instance.track(ProductEvents.alunosHelpOpened);
    await showAlunosListHelpSheet(context);
  }

  Future<void> _refreshHome() async {
    AlunosHomeClientCache.clear();
    invalidateAlunosCaches(ref);
    await ref.read(alunosHomeProvider.future);
    AnalyticsService.instance.track(ProductEvents.alunosRefreshed);
    if (mounted) {
      FeedbackHelper.showSuccess(context, AlunosMicrocopy.painelAtualizado);
    }
  }

  void _toggleSelecionado(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  Future<void> _excluirSelecionados() async {
    final total = _selecionados.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showFxHomeSheet<bool>(
      context,
      builder: (_) => _ExcluirAlunosSheet(count: total, isDark: isDark),
    );
    if (confirmar != true) return;

    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    for (final id in List<int>.from(_selecionados)) {
      try {
        await repo.excluirAluno(id);
        sucesso++;
      } catch (_) {}
    }
    if (mounted) {
      invalidateAlunosCaches(ref);
      if (sucesso < total) {
        FeedbackHelper.showError(
          context,
          '${total - sucesso} de $total não puderam ser excluídos.',
        );
      }
      if (sucesso > 0) {
        FeedbackHelper.showSuccess(context, _deletedMessage(sucesso));
      }
      setState(() {
        _modoSelecao = false;
        _selecionados.clear();
      });
    }
  }

  bool get _temFinanceiro {
    final home = ref.read(alunosHomeProvider).valueOrNull;
    return (home?.planoFeatures ?? ref.read(planoFeaturesProvider).valueOrNull)
            ?.normalizeForTier()
            .financeiro ==
        true;
  }

  Future<void> _marcarPagosSelecionados() async {
    if (_selecionados.isEmpty) return;
    if (!_temFinanceiro) {
      await UpgradePromptSheet.show(
        context: context,
        featureName: 'Financeiro',
        capability: 'financeiro',
      );
      return;
    }
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post(
            '/api/financeiro/mensalidades/lote-pago',
            data: {'alunoIds': _selecionados.toList()},
          );
      if (mounted) {
        invalidateAlunosCaches(ref);
        FeedbackHelper.showSuccess(
          context,
          mensalidadesPagasMessage(_selecionados.length),
        );
        setState(() {
          _modoSelecao = false;
          _selecionados.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Nem todo 403 é paywall: RBAC e "sem permissão" também devolvem 403.
      // O catálogo de codigo decide; o resto cai no erro genérico.
      final surfaced = await UpgradePromptSheet.showFromError(
        context,
        e,
        fallbackFeatureName: 'Financeiro',
        fallbackCapability: 'financeiro',
        source: 'alunos_lote_pago',
      );
      if (surfaced) return;
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _atualizarStatusSelecionados(String novoStatus) async {
    if (_selecionados.isEmpty) return;
    final repo = AlunoRepository(ref.read(apiClientProvider));
    try {
      await repo.atualizarStatusLote(_selecionados.toList(), novoStatus);
      if (mounted) {
        invalidateAlunosCaches(ref);
        FeedbackHelper.showSuccess(
          context,
          alunosAtualizadosMessage(_selecionados.length),
        );
        setState(() {
          _modoSelecao = false;
          _selecionados.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _showBulkActionsSheet() {
    if (_selecionados.isEmpty) return;
    AnalyticsService.instance.track(
      ProductEvents.alunosBulkOpened,
      props: {'count': _selecionados.length},
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtd = _selecionados.length;
    final home = ref.read(alunosHomeProvider).valueOrNull;
    final alunos = <Aluno>[
      ...?home?.alunos,
      ...ref.read(alunosHomeTailProvider).alunos,
    ];
    final mostrarMarcarPago = showAlunosBulkPayCta(
      alunos.where((a) => _selecionados.contains(a.id)),
      temFinanceiro: _temFinanceiro,
    );
    showFxHomeSheet<void>(
      context,
      builder:
          (sheetContext) => _AlunosBulkActionsSheet(
            count: qtd,
            isDark: isDark,
            mostrarMarcarPago: mostrarMarcarPago,
            onMarcarPagos: () {
              Navigator.pop(sheetContext);
              _marcarPagosSelecionados();
            },
            onAtualizarStatus: (status) {
              Navigator.pop(sheetContext);
              _atualizarStatusSelecionados(status);
            },
            onExcluir: () {
              Navigator.pop(sheetContext);
              _excluirSelecionados();
            },
          ),
    );
  }

  bool get _hasActiveFilter => _filtro != AlunoFiltro.todos;

  String _filtroLabel(AlunoFiltro filtro) => switch (filtro) {
    AlunoFiltro.todos => 'todos',
    AlunoFiltro.contatoHoje => 'precisando de contato hoje',
    AlunoFiltro.ativos => 'ativos',
    AlunoFiltro.inadimplentes => 'em atraso',
    AlunoFiltro.risco => 'em risco',
    AlunoFiltro.novos => 'convites pendentes',
  };

  static String _plural(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _deletedMessage(int total) {
    if (total == 0) return 'Nenhum aluno foi excluído.';
    return '${_plural(total, 'aluno excluído', 'alunos excluídos')}.';
  }

  String _selectionSummary() {
    if (_selecionados.isEmpty) return 'Selecione os alunos';
    return _plural(_selecionados.length, 'selecionado', 'selecionados');
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(alunosHomeProvider);
    ref.listen<AsyncValue<AlunosHomeBundle>>(alunosHomeProvider, (_, next) {
      next.whenData((home) {
        ref.read(alunosHomeTailProvider.notifier).reset(home.page);
        if (mounted) {
          setState(() {
            _displayHome = home;
            _listRefreshing = false;
            _fetchedAt = AlunosHomeClientCache.fetchedAt ?? DateTime.now();
          });
        }
      });
    });

    final home = _displayHome ?? homeAsync.valueOrNull;
    final count = home?.stats.total ?? 0;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final clearFilter = _hasActiveFilter && !_modoSelecao;

    return fxScreenA11yScope(
      label: AlunosMicrocopy.screenA11y,
      child: PopScope(
        canPop: !keyboardOpen && !_hasActiveFilter && !_modoSelecao,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (keyboardOpen || _searchFocusNode.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          if (_modoSelecao) {
            _toggleModoSelecao();
            return;
          }
          if (_hasActiveFilter) _handleHeaderBack();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: context.alunosL10n.alunosTitle,
            subtitle:
                _modoSelecao
                    ? _selectionSummary()
                    : FxHubFreshness.joinCount(
                      alunosListCountLabel(count),
                      freshness,
                    ),
            showBack: clearFilter,
            onBack:
                clearFilter
                    ? () {
                      FxKeyboardDismissScope.dismiss();
                      _handleHeaderBack();
                    }
                    : null,
            actions: [
              FxHelpIconButton(
                tooltip: AlunosMicrocopy.helpA11y,
                onTap: _openHelp,
              ),
              IconButton(
                tooltip: AlunosMicrocopy.selectA11y,
                onPressed: _toggleModoSelecao,
                icon: Icon(
                  _modoSelecao ? Icons.close_rounded : Icons.checklist_rounded,
                ),
              ),
            ],
          ),
          body:
              _displayHome != null
                  ? _buildAlunosHomeData(
                    _displayHome!,
                    listRefreshing: _listRefreshing || homeAsync.isLoading,
                  )
                  : homeAsync.when(
                    loading: () => const AlunosLoadingScaffold(),
                    error:
                        (e, _) => AlunosErrorScaffold(
                          error: e,
                          onRetry: () => invalidateAlunosCaches(ref),
                        ),
                    data: _buildAlunosHomeData,
                  ),
        ),
      ),
    );
  }
}
