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
        props: {
          'filtro': _filtro.name,
          'compact': _listaCompacta,
        },
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
    final plano = home?.planoFeatures ?? ref.read(planoFeaturesProvider).valueOrNull;
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
    setState(() => _filtro = filtro);
    _syncHomeQuery();
    _scrollChipIntoView(filtro);
    if (track) {
      AnalyticsService.instance.track(
        ProductEvents.alunosFilterChanged,
        props: {'filtro': filtro.name},
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
    setState(() => _ordenacao = ordenacao);
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
    HapticFeedback.selectionClick();
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
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      barrierColor: Colors.black.withValues(alpha: 0.34),
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

  Future<void> _marcarPagosSelecionados() async {
    if (_selecionados.isEmpty) return;
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
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
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
    );
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
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
        setState(() => _fetchedAt = AlunosHomeClientCache.fetchedAt ?? DateTime.now());
      });
    });

    return fxScreenA11yScope(
      label: AlunosMicrocopy.screenA11y,
      child: PopScope(
        canPop: !_hasActiveFilter,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_hasActiveFilter) _handleHeaderBack();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: homeAsync.when(
            loading: () => const AlunosLoadingScaffold(),
            error:
                (e, _) => AlunosErrorScaffold(
                  error: e,
                  onRetry: () => invalidateAlunosCaches(ref),
                ),
            data: (home) {
              return FxContentWidthLimiter(child: _buildAlunosHomeData(home));
            },
          ),
        ),
      ),
    );
  }
}
