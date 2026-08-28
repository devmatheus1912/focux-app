part of 'treinos_list_screen.dart';

class _TreinosListViewState extends ConsumerState<_TreinosListView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  final DateTime _openedAt = DateTime.now();
  Timer? _searchDebounce;
  String _query = '';
  bool _selectionMode = false;
  bool _viewTracked = false;
  bool _ttvTracked = false;
  DateTime? _fetchedAt;

  Map<String, Object?> get _analyticsScope => {
    'scope': widget.alunoId == null ? 'library' : 'aluno',
  };

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(Treino treino) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      treino.nome,
      treino.objetivo,
      treino.descricao,
      treino.nivel,
      '${treino.exerciciosCount} exercicios',
      treino.isTemplate ? 'template base' : null,
    ].whereType<String>().any((value) => value.toLowerCase().contains(query));
  }

  void _toggleSelection(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = true;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _startSelection(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      AnalyticsService.instance.track(
        ProductEvents.treinosSearchUsed,
        props: {..._analyticsScope, 'has_query': _query.trim().isNotEmpty},
      );
    });
  }

  Future<void> _openHelp() {
    AnalyticsService.instance.track(
      ProductEvents.treinosHelpOpened,
      props: _analyticsScope,
    );
    return showTreinosListHelpSheet(context);
  }

  Future<void> _assignTreino(Treino treino) async {
    try {
      final alunos = await ref.read(alunosProvider.future);
      if (!mounted) return;
      final selected = await showFxHomeSheet<int>(
        context,
        builder: (_) => _AssignWorkoutSheet(alunos: alunos),
      );
      if (selected == null) return;

      await ref
          .read(treinoRepositoryProvider)
          .atribuirAluno(treino.id, selected);
      invalidateTreinosCaches(ref);
      ref.invalidate(treinosDoAlunoProvider(selected));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Treino atribuído ao aluno.');
      AnalyticsService.instance.track(
        ProductEvents.treinosAssigned,
        props: _analyticsScope,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível atribuir o treino.'),
      );
    }
  }

  Future<void> _duplicateTreino(Treino treino) async {
    try {
      await ref.read(treinoRepositoryProvider).duplicar(treino.id);
      invalidateTreinosCaches(ref);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Treino duplicado.');
      AnalyticsService.instance.track(
        ProductEvents.treinosDuplicated,
        props: _analyticsScope,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível duplicar o treino.'),
      );
    }
  }

  Future<void> _cloneTreinoParaAluno(Treino treino) async {
    try {
      final alunos = await ref.read(alunosProvider.future);
      if (!mounted) return;
      final selected = await showFxHomeSheet<int>(
        context,
        builder: (_) => _AssignWorkoutSheet(alunos: alunos),
      );
      if (selected == null) return;

      await ref
          .read(treinoRepositoryProvider)
          .clonarParaAluno(treino.id, selected);
      invalidateTreinosCaches(ref);
      ref.invalidate(treinosDoAlunoProvider(selected));
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Cópia dedicada criada para o aluno.',
      );
      AnalyticsService.instance.track(
        ProductEvents.treinosCloned,
        props: _analyticsScope,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível copiar o treino.'),
      );
    }
  }

  Future<void> _openTreinoActions(Treino treino) async {
    AnalyticsService.instance.track(
      ProductEvents.treinosActionOpened,
      props: _analyticsScope,
    );
    final action = await showFxHomeSheet<_TreinoAction>(
      context,
      builder:
          (_) => _TreinoActionsSheet(
            treino: treino,
            canAssign: widget.alunoId == null,
          ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _TreinoAction.open:
        context.push(
          '/treinos/${treino.id}',
          extra:
              widget.alunoId == null
                  ? null
                  : {'alunoId': widget.alunoId, 'alunoNome': widget.alunoNome},
        );
        break;
      case _TreinoAction.assign:
        await _assignTreino(treino);
        break;
      case _TreinoAction.clone:
        await _cloneTreinoParaAluno(treino);
        break;
      case _TreinoAction.duplicate:
        await _duplicateTreino(treino);
        break;
      case _TreinoAction.delete:
        await _deleteTreinos([treino], source: 'card');
        break;
    }
  }

  Future<void> _deleteTreinos(
    List<Treino> treinos, {
    required String source,
  }) async {
    if (treinos.isEmpty) return;
    final count = treinos.length;
    final confirmed = await showFxHomeSheet<bool>(
      context,
      builder:
          (context) => _DeleteWorkoutSheet(
            count: count,
            name: count == 1 ? displayWorkoutName(treinos.first.nome) : null,
            unlinkOnly: widget.alunoId != null,
          ),
    );
    if (confirmed != true) return;

    final repository = ref.read(treinoRepositoryProvider);
    try {
      for (final treino in treinos) {
        if (widget.alunoId == null) {
          await repository.excluirTreino(treino.id);
        } else {
          await repository.desvincularAluno(widget.alunoId!, treino.id);
        }
      }
      _clearSelection();
      if (widget.alunoId == null) {
        invalidateTreinosCaches(ref);
      } else {
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        count == 1 ? 'Treino removido.' : '$count treinos removidos.',
      );
      AnalyticsService.instance.track(
        ProductEvents.treinosDeleted,
        props: {
          ..._analyticsScope,
          'count': count,
          'unlink': widget.alunoId != null,
          'source': source,
        },
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível remover o treino.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final treinosSource =
        widget.alunoId == null
            ? treinosProvider
            : treinosDoAlunoProvider(widget.alunoId!);
    final treinosAsync = ref.watch(treinosSource);
    final homeBundle =
        widget.alunoId == null ? ref.watch(treinosHomeProvider).valueOrNull : null;
    final uiHints = homeBundle?.uiHints;
    ref.listen<AsyncValue<List<Treino>>>(treinosSource, (_, next) {
      if (!next.isLoading && next.hasValue) {
        setState(() => _fetchedAt = DateTime.now());
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    Future<void> refresh({bool track = true}) async {
      if (track) {
        AnalyticsService.instance.track(
          ProductEvents.treinosRefreshed,
          props: _analyticsScope,
        );
      }
      if (widget.alunoId == null) {
        invalidateTreinosCaches(ref);
      } else {
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
    }

    Future<void> createWorkout() async {
      AnalyticsService.instance.track(
        ProductEvents.treinosCreateTapped,
        props: _analyticsScope,
      );
      final criado = await context.push<bool>(
        '/treinos/novo',
        extra:
            widget.alunoId == null
                ? null
                : {'alunoId': widget.alunoId, 'alunoNome': widget.alunoNome},
      );
      if (criado == true) {
        await refresh(track: false);
      }
    }

    return fxScreenA11yScope(
      label: widget.alunoId == null ? 'Treinos' : 'Treinos do aluno',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: treinosAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.fromLTRB(TokensStrip.s5, 86, 20, 0),
                  child: SkeletonList(count: 5),
                ),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry: refresh,
                ),
            data: (treinos) {
              if (!_viewTracked) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _viewTracked) return;
                  _viewTracked = true;
                  AnalyticsService.instance.track(
                    ProductEvents.treinosViewed,
                    props: {
                      ..._analyticsScope,
                      'count': treinos.length,
                      'prontos': treinos.where((t) => t.pronto).length,
                    },
                  );
                  if (!_ttvTracked) {
                    _ttvTracked = true;
                    AnalyticsService.instance.track(
                      ProductEvents.treinosTtv,
                      props: {
                        ..._analyticsScope,
                        'ms':
                            DateTime.now().difference(_openedAt).inMilliseconds,
                        'count': treinos.length,
                      },
                    );
                  }
                });
              }
              final filteredTreinos = treinos.where(_matchesQuery).toList();
              final selectedTreinos =
                  treinos
                      .where((treino) => _selectedIds.contains(treino.id))
                      .toList();
              final singlePlan = treinos.length == 1;

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: refresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _TreinosHeader(
                              alunoId: widget.alunoId,
                              alunoNome: widget.alunoNome,
                              isDark: isDark,
                              freshnessLabel: freshnessLabel,
                              selectionMode: _selectionMode,
                              selectedCount: _selectedIds.length,
                              onBack:
                                  widget.alunoId == null
                                      ? null
                                      : () => safePopOrGo(
                                        context,
                                        '/alunos/${widget.alunoId}',
                                      ),
                              onHelp: _openHelp,
                              onCreate: createWorkout,
                              onSelectAll:
                                  filteredTreinos.isEmpty
                                      ? null
                                      : () {
                                        setState(() {
                                          _selectionMode = true;
                                          _selectedIds
                                            ..clear()
                                            ..addAll(
                                              filteredTreinos.map(
                                                (treino) => treino.id,
                                              ),
                                            );
                                        });
                                      },
                              onCancelSelection: _clearSelection,
                            ),
                          ),
                          if (treinos.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  TreinosLayout.screenPadding,
                                  8,
                                  TreinosLayout.screenPadding,
                                  32,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: FxSettingsGroup(
                                    header:
                                        widget.alunoId == null
                                            ? 'Biblioteca'
                                            : 'Plano do aluno',
                                    caption:
                                        widget.alunoId == null
                                            ? (uiHints?.emptySubtitle ??
                                                TreinosListLabels.emptySubtitle(
                                                  alunoNome: widget.alunoNome,
                                                ))
                                            : TreinosListLabels.emptySubtitle(
                                              alunoNome: widget.alunoNome,
                                            ),
                                    accent: primary,
                                    children: [
                                      FxSettingsTile(
                                        icon: Icons.add_rounded,
                                        label:
                                            widget.alunoId == null
                                                ? (uiHints?.createCtaLabel ??
                                                    'Criar treino')
                                                : 'Criar treino',
                                        subtitle:
                                            widget.alunoId == null
                                                ? (uiHints?.emptyTitle ??
                                                    TreinosListLabels.emptyTitle(
                                                      alunoNome:
                                                          widget.alunoNome,
                                                    ))
                                                : TreinosListLabels.emptyTitle(
                                                  alunoNome: widget.alunoNome,
                                                ),
                                        value: '',
                                        highlight: true,
                                        showDivider: false,
                                        onTap: createWorkout,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            if (!_selectionMode &&
                                uiHints?.emMontagemHint != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    TreinosLayout.screenPadding,
                                    0,
                                    TreinosLayout.screenPadding,
                                    10,
                                  ),
                                  child: Text(
                                    uiHints!.emMontagemHint!,
                                    style: FocuxHubTypography.bodyMuted(
                                      color:
                                          isDark
                                              ? EagleTokens.darkInkMute
                                              : TokensStrip.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_selectionMode)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    TreinosLayout.screenPadding,
                                    0,
                                    TreinosLayout.screenPadding,
                                    singlePlan ? 12 : 14,
                                  ),
                                  child: _LibraryControls(
                                    controller: _searchController,
                                    query: _query,
                                    isDark: isDark,
                                    primary: primary,
                                    onQueryChanged: _onQueryChanged,
                                    onClearQuery: _clearQuery,
                                  ),
                                ),
                              ),
                            if (!_selectionMode)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    TreinosLayout.screenPadding,
                                    0,
                                    TreinosLayout.screenPadding,
                                    12,
                                  ),
                                  child: _SectionHeader(
                                    title:
                                        widget.alunoId == null
                                            ? 'Biblioteca'
                                            : 'Plano do aluno',
                                    action:
                                        _query.trim().isEmpty
                                            ? (uiHints?.libraryCaption ??
                                                TreinosListLabels.libraryCaption(
                                                  prontos:
                                                      treinos
                                                          .where((t) => t.pronto)
                                                          .length,
                                                  exercises: treinos.fold<int>(
                                                    0,
                                                    (sum, t) =>
                                                        sum + t.exerciciosCount,
                                                  ),
                                                ))
                                            : '${filteredTreinos.length} de ${treinos.length}',
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            if (filteredTreinos.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: FxEmptyState(
                                  icon: 'search',
                                  title: 'Nada encontrado',
                                  subtitle:
                                      'Ajuste a busca para encontrar outro treino da biblioteca.',
                                  action: FxEmptyAction(
                                    label: 'Limpar busca',
                                    onTap: _clearQuery,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  TreinosLayout.screenPadding,
                                  _selectionMode ? 4 : 0,
                                  TreinosLayout.screenPadding,
                                  TreinosLayout.listBottomGap(context),
                                ),
                                sliver: SliverList.separated(
                                  itemCount: filteredTreinos.length,
                                  separatorBuilder:
                                      (_, __) => SizedBox(
                                        height: TreinosLayout.listItemGap,
                                      ),
                                  itemBuilder:
                                      (context, i) => FxStaggerItem(
                                        index: i,
                                        child: _TreinoCard(
                                          treino: filteredTreinos[i],
                                          isDark: isDark,
                                          primary: primary,
                                          alunoId: widget.alunoId,
                                          alunoNome: widget.alunoNome,
                                          selectionMode: _selectionMode,
                                          selected: _selectedIds.contains(
                                            filteredTreinos[i].id,
                                          ),
                                          onToggleSelection:
                                              () => _toggleSelection(
                                                filteredTreinos[i].id,
                                              ),
                                          onStartSelection:
                                              () => _startSelection(
                                                filteredTreinos[i].id,
                                              ),
                                          onActions:
                                              () => _openTreinoActions(
                                                filteredTreinos[i],
                                              ),
                                        ),
                                      ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_selectionMode && selectedTreinos.isNotEmpty)
                    _TreinosBulkBar(
                      allSelected:
                          selectedTreinos.length == filteredTreinos.length &&
                          filteredTreinos.isNotEmpty,
                      isDark: isDark,
                      onToggleAll: () {
                        HapticFeedback.selectionClick();
                        if (_selectedIds.length == filteredTreinos.length) {
                          _clearSelection();
                        } else {
                          setState(() {
                            _selectionMode = true;
                            _selectedIds
                              ..clear()
                              ..addAll(
                                filteredTreinos.map((treino) => treino.id),
                              );
                          });
                        }
                      },
                      onDelete: () {
                        AnalyticsService.instance.track(
                          ProductEvents.treinosBulkOpened,
                          props: {
                            ..._analyticsScope,
                            'count': selectedTreinos.length,
                          },
                        );
                        _deleteTreinos(selectedTreinos, source: 'bulk');
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
