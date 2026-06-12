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
    final criado = await context.push<bool>('/alunos/novo');
    if (criado == true) {
      ref.invalidate(alunosProvider);
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
      ref.invalidate(alunosProvider);
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
        ref.invalidate(alunosProvider);
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
        ref.invalidate(alunosProvider);
        ref.invalidate(alunosStatsProvider);
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

  Future<void> _showListOptions() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(isDark);
        final ink = chrome.ink;
        final mute = chrome.mute;
        final line = chrome.line;
        final primary = Theme.of(ctx).colorScheme.primary;
        final linkColor = BrandPalette.sectionLink(primary, dark: isDark);

        Widget option({
          required String title,
          required String subtitle,
          required IconData icon,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
              Navigator.pop(ctx);
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    selected
                        ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      selected
                          ? primary.withValues(alpha: 0.35)
                          : line.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? primary
                              : primary.withValues(alpha: isDark ? 0.18 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : icon,
                      color: selected ? Colors.white : primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: TokensStrip.fontBody,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: TokensStrip.fontBodySm,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sheetMaxHeight = MediaQuery.sizeOf(ctx).height * 0.72;

        return DecoratedBox(
          decoration: chrome.bottomSheet(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Organizar alunos',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: TokensStrip.fontH2,
                            fontWeight: TokensStrip.weightH2,
                            letterSpacing: TokensStrip.trackingH2,
                            height: 1.2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filtro = AlunoFiltro.todos;
                            _ordenacao = AlunoOrdenacao.prioridade;
                          });
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: linkColor,
                          textStyle: AppTypography.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: TokensStrip.fontBodySm,
                          ),
                        ),
                        child: const Text('Redefinir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha como a lista deve aparecer agora.',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: TokensStrip.fontBodySm,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  option(
                    title: 'Prioridade do dia',
                    subtitle:
                        'Risco, inadimplência e convites aparecem primeiro.',
                    icon: Icons.priority_high_rounded,
                    selected: _ordenacao == AlunoOrdenacao.prioridade,
                    onTap:
                        () => setState(
                          () => _ordenacao = AlunoOrdenacao.prioridade,
                        ),
                  ),
                  const SizedBox(height: 8),
                  option(
                    title: 'Nome A-Z',
                    subtitle: 'Lista alfabética para encontrar alunos rápido.',
                    icon: Icons.sort_by_alpha_rounded,
                    selected: _ordenacao == AlunoOrdenacao.nome,
                    onTap:
                        () => setState(() => _ordenacao = AlunoOrdenacao.nome),
                  ),
                  const SizedBox(height: 8),
                  option(
                    title: 'Sem foto primeiro',
                    subtitle:
                        'Ajuda a completar perfis que ainda parecem genéricos.',
                    icon: Icons.no_photography_outlined,
                    selected: _ordenacao == AlunoOrdenacao.semFoto,
                    onTap:
                        () =>
                            setState(() => _ordenacao = AlunoOrdenacao.semFoto),
                  ),
                  const SizedBox(height: 8),
                  option(
                    title: 'Lista compacta',
                    subtitle:
                        'Menos ruído: oculta e-mail na lista e reduz o card.',
                    icon: Icons.density_small_rounded,
                    selected: _listaCompacta,
                    onTap: () async {
                      final next = !_listaCompacta;
                      setState(() => _listaCompacta = next);
                      await AlunoListPreferencesStore.saveCompact(next);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Atalhos de foco',
                    style: AppTypography.inter(
                      color: ink,
                      fontSize: TokensStrip.fontBodySm,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SheetShortcutChip(
                        label: 'Contato hoje',
                        selected: _filtro == AlunoFiltro.contatoHoje,
                        onTap: () {
                          setState(() => _filtro = AlunoFiltro.contatoHoje);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Risco alto',
                        selected: _filtro == AlunoFiltro.risco,
                        onTap: () {
                          setState(() => _filtro = AlunoFiltro.risco);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Inadimplentes',
                        selected: _filtro == AlunoFiltro.inadimplentes,
                        onTap: () {
                          setState(() => _filtro = AlunoFiltro.inadimplentes);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Convites',
                        selected: _filtro == AlunoFiltro.novos,
                        onTap: () {
                          setState(() => _filtro = AlunoFiltro.novos);
                          Navigator.pop(ctx);
                        },
                      ),
                      _SheetShortcutChip(
                        label: 'Todos',
                        selected: _filtro == AlunoFiltro.todos,
                        onTap: () {
                          setState(() => _filtro = AlunoFiltro.todos);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final statsAsync = ref.watch(alunosStatsProvider);
    final configAsync = ref.watch(alertasConfigProvider);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final diasLimite =
        configAsync.valueOrNull?.diasSemTreino ??
        AlunoFollowUpStore.diasSemTreinoLimite;

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
        body: alunosAsync.when(
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
              (e, _) => _AlunosErrorState(
                isDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () {
                  ref.invalidate(alunosProvider);
                  ref.invalidate(alunosStatsProvider);
                },
              ),
          data: (alunos) {
            final stats = statsAsync.valueOrNull;
            final filtrados = _filtrarAlunos(
              alunos,
              diasSemTreinoLimite: diasLimite,
            );
            final ativosCount =
                stats?.totalAtivos ??
                alunos
                    .where(
                      (a) =>
                          a.status == 'ATIVO' &&
                          a.statusFinanceiro != 'INADIMPLENTE',
                    )
                    .length;
            final inadCount =
                stats?.totalInadimplentes ??
                alunos
                    .where(
                      (a) =>
                          a.statusFinanceiro == 'INADIMPLENTE' ||
                          a.inadimplente,
                    )
                    .length;
            final riscoCount =
                stats?.totalRiscoAlto ?? alunos.where((a) => a.emRisco).length;
            final contatoCount = _contatoHojeCount(
              alunos,
              diasSemTreinoLimite: diasLimite,
            );
            final novosCount =
                stats?.totalConvites ??
                alunos.where((a) => a.senhaProvisoria != null).length;
            final headerOps =
                _modoSelecao
                    ? _selectionSummary()
                    : '$contatoCount contato · $riscoCount risco · $novosCount convites';
            final showHeaderBack = !_modoSelecao && _hasActiveFilter;
            final headerBackFromDashboard = _hasDeepLinkFiltro(context);
            final triageContextActive =
                !_modoSelecao &&
                _filtro == AlunoFiltro.todos &&
                (contatoCount > 0 || riscoCount > 0);
            final listBottomGap =
                FocuxPlatform.isCompact(context) ? 28.0 : 36.0;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxPremiumEntrance(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header (Alunos + Botão Adicionar)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s5,
                            14,
                            20,
                            14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (showHeaderBack) ...[
                                Semantics(
                                  button: true,
                                  label:
                                      headerBackFromDashboard
                                          ? 'Voltar para Hoje'
                                          : 'Limpar filtro',
                                  child: InkWell(
                                    onTap: _handleHeaderBack,
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: chrome.headerAction(
                                        radius: 20,
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 18,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      headerOps,
                                      style: AppTypography.inter(
                                        fontSize: TokensStrip.fontBodySm,
                                        color:
                                            _modoSelecao
                                                ? BrandPalette.sectionAction(
                                                  primary,
                                                  dark: isDark,
                                                )
                                                : mute,
                                        fontWeight:
                                            _modoSelecao
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                        letterSpacing: _modoSelecao ? 1.2 : 0,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Alunos',
                                      style: AppTypography.inter(
                                        fontSize: TokensStrip.fontH1,
                                        color: ink,
                                        fontWeight: TokensStrip.weightH1,
                                        letterSpacing: TokensStrip.trackingH1,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_modoSelecao) ...[
                                InkWell(
                                  onTap: _toggleModoSelecao,
                                  borderRadius: BorderRadius.circular(44),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: chrome.headerAction(radius: 22),
                                    child: Icon(
                                      Icons.close,
                                      size: 22,
                                      color: ink,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const ShellThemeToggle(size: 40),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _toggleModoSelecao,
                                  borderRadius: BorderRadius.circular(44),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: chrome.headerAction(radius: 22),
                                    child: Icon(
                                      Icons.checklist_rounded,
                                      size: 22,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FxGlowSurface(
                                  color: primary,
                                  enabled: true,
                                  intensity: 0.9,
                                  borderRadius: 44,
                                  child: FxSpringButton(
                                    onTap: _adicionarAluno,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.fromLTRB(13, 3, 8, 3),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? EagleTokens.darkCard
                                      : Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color:
                                    _searchFocusNode.hasFocus
                                        ? primary.withValues(alpha: 0.32)
                                        : (isDark
                                            ? EagleTokens.darkLine
                                            : TokensStrip.borderDefault),
                                width: _searchFocusNode.hasFocus ? 1.2 : 1,
                              ),
                              boxShadow: [
                                if (_searchFocusNode.hasFocus && !isDark)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -12,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color:
                                        _searchFocusNode.hasFocus
                                            ? primary.withValues(alpha: 0.08)
                                            : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color:
                                        _searchFocusNode.hasFocus
                                            ? primary
                                            : mute,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onChanged: (value) {
                                      setState(() => _query = value);
                                    },
                                    textInputAction: TextInputAction.search,
                                    cursorColor: primary,
                                    style: AppTypography.inter(
                                      fontSize: TokensStrip.fontBody,
                                      color: ink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      hintText: 'Buscar por nome ou objetivo',
                                      hintStyle: AppTypography.inter(
                                        fontSize: TokensStrip.fontBody,
                                        color: mute,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_query.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: mute,
                                      ),
                                    ),
                                  )
                                else
                                  Tooltip(
                                    message: 'Organizar lista',
                                    child: InkWell(
                                      onTap: _showListOptions,
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: primary.withValues(
                                            alpha: isDark ? 0.14 : 0.07,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              size: 18,
                                              color: primary,
                                            ),
                                            if (_ordenacao !=
                                                    AlunoOrdenacao.prioridade ||
                                                _filtro != AlunoFiltro.todos)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    color: primary,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          isDark
                                                              ? EagleTokens
                                                                  .darkCard
                                                              : TokensStrip
                                                                  .cardBg,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Filter Chips
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            4,
                            16,
                            10,
                          ),
                          child: FxHorizontalScrollPeek(
                            showPeek: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FxChip(
                                    label: 'Todos',
                                    count: alunos.length,
                                    isSelected: _filtro == AlunoFiltro.todos,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () => _filtro = AlunoFiltro.todos,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FxChip(
                                    label: 'Contato hoje',
                                    count: contatoCount,
                                    isSelected:
                                        _filtro == AlunoFiltro.contatoHoje,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () =>
                                              _filtro = AlunoFiltro.contatoHoje,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FxChip(
                                    label: 'Ativos',
                                    count: ativosCount,
                                    isSelected: _filtro == AlunoFiltro.ativos,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () => _filtro = AlunoFiltro.ativos,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FxChip(
                                    label: 'Inadimplentes',
                                    count: inadCount,
                                    isSelected:
                                        _filtro == AlunoFiltro.inadimplentes,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () =>
                                              _filtro =
                                                  AlunoFiltro.inadimplentes,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FxChip(
                                    label: 'Risco alto',
                                    count: riscoCount,
                                    isSelected: _filtro == AlunoFiltro.risco,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () => _filtro = AlunoFiltro.risco,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FxChip(
                                    label: 'Convites',
                                    count: novosCount,
                                    isSelected: _filtro == AlunoFiltro.novos,
                                    isDark: isDark,
                                    onTap:
                                        () => setState(
                                          () => _filtro = AlunoFiltro.novos,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!_modoSelecao &&
                      _filtro == AlunoFiltro.todos &&
                      contatoCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _AlunosTriageBanner(
                        count: contatoCount,
                        isDark: isDark,
                        title: '$contatoCount precisam de contato hoje',
                        subtitle:
                            'Risco, inadimplência ou $diasLimite+ dias sem treino',
                        onTap:
                            () => setState(
                              () => _filtro = AlunoFiltro.contatoHoje,
                            ),
                      ),
                    )
                  else if (!_modoSelecao &&
                      _filtro == AlunoFiltro.todos &&
                      riscoCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _AlunosTriageBanner(
                        count: riscoCount,
                        isDark: isDark,
                        title:
                            '$riscoCount aluno${riscoCount == 1 ? '' : 's'} em risco',
                        subtitle: 'Priorize contato e retomada de treino hoje',
                        onTap:
                            () => setState(() => _filtro = AlunoFiltro.risco),
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
                              isDark: isDark,
                              onAdd: _adicionarAluno,
                              onClear:
                                  _query.trim().isEmpty
                                      ? null
                                      : () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                              onClearFilter:
                                  _hasActiveFilter
                                      ? () => setState(
                                        () => _filtro = AlunoFiltro.todos,
                                      )
                                      : null,
                            )
                            : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(alunosProvider);
                                ref.invalidate(alunosStatsProvider);
                                ref.invalidate(alertasConfigProvider);
                              },
                              child: ListView.separated(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 8,
                                  bottom: listBottomGap,
                                ),
                                itemCount: filtrados.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final a = filtrados[i];
                                  return FxStaggerItem(
                                    index: i,
                                    child: _AlunoCardFX(
                                      aluno: a,
                                      modoSelecao: _modoSelecao,
                                      isSelected: _selecionados.contains(a.id),
                                      onToggle: () => _toggleSelecionado(a.id),
                                      onLongPress:
                                          _modoSelecao
                                              ? null
                                              : _toggleModoSelecao,
                                      activeFiltro: _filtro,
                                      triageContextActive: triageContextActive,
                                      diasSemTreinoLimite: diasLimite,
                                      compact: _listaCompacta,
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),

                  // Bottom action bar (seleção)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                                                    : TokensStrip.borderDefault,
                                          ),
                                          foregroundColor: ink,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
          },
        ),
        ),
      ),
    );
  }
}
