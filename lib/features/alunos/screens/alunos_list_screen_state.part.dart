part of 'alunos_list_screen.dart';

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  AlunoFiltro _filtro = AlunoFiltro.todos;
  AlunoOrdenacao _ordenacao = AlunoOrdenacao.prioridade;
  bool _modoSelecao = false;
  final Set<int> _selecionados = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _ignoredDeepLinkFiltro = false;
  bool _listaCompacta = false;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _filtro = widget.initialFiltro;
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadListPreferences();
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

    if (!fromDashboard) return;

    safePopOrGo(context, '/dashboard/personal');
  }

  @override
  void dispose() {
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
    AnalyticsService.instance.track(
      ProductEvents.alunosAddTapped,
      props: {'feature': 'alunos'},
    );
    final criado = await context.push<bool>('/alunos/novo');
    if (criado == true) {
      invalidateAlunosCaches(ref);
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
      backgroundColor: Colors.transparent,
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
      FeedbackHelper.showSuccess(context, _deletedMessage(sucesso));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtd = _selecionados.length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) => _AlunosBulkActionsSheet(
            count: qtd,
            isDark: isDark,
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

  List<Aluno> _filtrarAlunos(
    List<Aluno> todos, {
    required int diasSemTreinoLimite,
  }) {
    final porStatus = switch (_filtro) {
      AlunoFiltro.todos => todos,
      AlunoFiltro.contatoHoje =>
        todos
            .where(
              (a) => alunoPrecisaContatoHoje(
                a,
                diasSemTreinoLimite: diasSemTreinoLimite,
              ),
            )
            .toList(),
      AlunoFiltro.ativos =>
        todos
            .where(
              (a) =>
                  a.status == 'ATIVO' && a.statusFinanceiro != 'INADIMPLENTE',
            )
            .toList(),
      AlunoFiltro.inadimplentes =>
        todos
            .where(
              (a) => a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente,
            )
            .toList(),
      AlunoFiltro.risco => todos.where((a) => a.emRisco).toList(),
      AlunoFiltro.novos =>
        todos.where((a) => a.senhaProvisoria != null).toList(),
    };

    final busca = _fold(_query.trim());
    if (busca.isEmpty) {
      return _ordenarAlunos(
        porStatus,
        diasSemTreinoLimite: diasSemTreinoLimite,
      );
    }

    final encontrados =
        porStatus.where((a) {
          final alvo = _fold(
            '${a.nome} ${a.email} ${a.objetivo ?? ''} ${a.statusFinanceiro} '
            '${a.telefone ?? ''} ${a.whatsapp ?? ''}',
          );
          return alvo.contains(busca);
        }).toList();

    return _ordenarAlunos(
      encontrados,
      diasSemTreinoLimite: diasSemTreinoLimite,
    );
  }

  bool get _hasActiveFilter => _filtro != AlunoFiltro.todos;

  String _filtroLabel(AlunoFiltro filtro) => switch (filtro) {
    AlunoFiltro.todos => 'todos',
    AlunoFiltro.contatoHoje => 'precisando de contato hoje',
    AlunoFiltro.ativos => 'ativos',
    AlunoFiltro.inadimplentes => 'inadimplentes',
    AlunoFiltro.risco => 'em risco',
    AlunoFiltro.novos => 'convites pendentes',
  };

  int _contatoHojeCount(
    List<Aluno> alunos, {
    required int diasSemTreinoLimite,
  }) {
    return alunos
        .where(
          (a) => alunoPrecisaContatoHoje(
            a,
            diasSemTreinoLimite: diasSemTreinoLimite,
          ),
        )
        .length;
  }

  List<Aluno> _ordenarAlunos(
    List<Aluno> alunos, {
    required int diasSemTreinoLimite,
  }) {
    final ordenados = List<Aluno>.from(alunos);
    switch (_ordenacao) {
      case AlunoOrdenacao.prioridade:
        ordenados.sort((a, b) {
          final scoreA = _priorityScore(
            a,
            diasSemTreinoLimite: diasSemTreinoLimite,
          );
          final scoreB = _priorityScore(
            b,
            diasSemTreinoLimite: diasSemTreinoLimite,
          );
          final score = scoreB.compareTo(scoreA);
          if (score != 0) return score;
          final diasA = a.diasSemTreino ?? 0;
          final diasB = b.diasSemTreino ?? 0;
          final diasCmp = diasB.compareTo(diasA);
          if (diasCmp != 0) return diasCmp;
          final aderA = a.aderenciaPercent ?? 100;
          final aderB = b.aderenciaPercent ?? 100;
          final aderCmp = aderA.compareTo(aderB);
          if (aderCmp != 0) return aderCmp;
          return _fold(a.nome).compareTo(_fold(b.nome));
        });
      case AlunoOrdenacao.nome:
        ordenados.sort((a, b) => _fold(a.nome).compareTo(_fold(b.nome)));
      case AlunoOrdenacao.semFoto:
        ordenados.sort((a, b) {
          final photo = _hasPhoto(
            a,
          ).toString().compareTo(_hasPhoto(b).toString());
          if (photo != 0) return photo;
          return _fold(a.nome).compareTo(_fold(b.nome));
        });
    }
    return ordenados;
  }

  int _priorityScore(Aluno aluno, {required int diasSemTreinoLimite}) {
    var score = 0;
    score += alunoContatoPriorityBoost(
      aluno,
      diasSemTreinoLimite: diasSemTreinoLimite,
    );
    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      score += 8;
    }
    if (aluno.emRisco) score += 6;
    final dias = aluno.diasSemTreino ?? 0;
    if (dias >= 7) {
      score += 4;
    } else if (dias >= diasSemTreinoLimite) {
      score += 2;
    }
    final aderencia = aluno.aderenciaPercent;
    if (aderencia != null && aderencia < 40) score += 2;
    if (aluno.senhaProvisoria != null) score += 3;
    if (!_hasPhoto(aluno)) score += 1;
    return score;
  }

  bool _hasPhoto(Aluno aluno) {
    return aluno.fotoUrl != null && aluno.fotoUrl!.trim().isNotEmpty;
  }

  static String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

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
      if (!next.isLoading && next.hasValue) {
        setState(() => _fetchedAt = DateTime.now());
      }
    });
    final isDark = ShellChrome.of(context).isDark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Lista de alunos',
      child: PopScope(
        canPop: !_hasActiveFilter,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_hasActiveFilter) _handleHeaderBack();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: homeAsync.when(
            loading:
                () => const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      86,
                      TokensStrip.s4,
                      0,
                    ),
                    child: SkeletonList(count: 6),
                  ),
                ),
            error:
                (e, _) => SafeArea(
                  child: FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: FocuxMicrocopy.erroAoCarregarAlunos,
                    message: friendlyError(e),
                    onRetry: () => invalidateAlunosCaches(ref),
                  ),
                ),
            data: (home) {
              return _buildAlunosHomeData(home);
            },
          ),
        ),
      ),
    );
  }
}
