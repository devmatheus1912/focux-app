part of 'treinos_list_screen.dart';

class _TreinosListViewState extends ConsumerState<_TreinosListView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
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
      final next = value.trim();
      if (widget.alunoId != null) {
        final current = ref.read(treinosDoAlunoQueryProvider(widget.alunoId!));
        if (current.q == next) return;
        ref.read(treinosDoAlunoQueryProvider(widget.alunoId!).notifier).state =
            TreinosAlunoQuery(q: next);
        return;
      }
      final current = ref.read(treinosHomeQueryProvider);
      if (current.q == next) return;
      ref.read(treinosHomeQueryProvider.notifier).state =
          TreinosHomeQuery(q: next);
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
      invalidateTreinosDoAluno(ref, selected);
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
      invalidateTreinosDoAluno(ref, selected);
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
        invalidateTreinosDoAluno(ref, widget.alunoId!);
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
    final fromLibrary = widget.alunoId == null;
    final alunoPageAsync =
        fromLibrary
            ? null
            : ref.watch(treinosDoAlunoPageProvider(widget.alunoId!));
    final treinosAsync =
        fromLibrary
            ? ref.watch(treinosProvider)
            : alunoPageAsync!.whenData((page) => page.treinos);
    final homeBundle =
        fromLibrary ? ref.watch(treinosHomeProvider).valueOrNull : null;
    final tail =
        fromLibrary
            ? ref.watch(treinosHomeTailProvider)
            : ref.watch(treinosDoAlunoTailProvider(widget.alunoId!));
    final uiHints = homeBundle?.uiHints;
    if (fromLibrary) {
      ref.listen<AsyncValue<List<Treino>>>(treinosProvider, (_, next) {
        if (!next.isLoading && next.hasValue) {
          setState(() => _fetchedAt = DateTime.now());
        }
      });
      ref.listen<AsyncValue<TreinosHomeBundle>>(treinosHomeProvider, (_, next) {
        next.whenData((home) {
          ref.read(treinosHomeTailProvider.notifier).reset(hasNext: home.hasNext);
        });
      });
    } else {
      ref.listen<AsyncValue<TreinosAlunoPage>>(
        treinosDoAlunoPageProvider(widget.alunoId!),
        (_, next) {
          if (!next.isLoading && next.hasValue) {
            setState(() => _fetchedAt = DateTime.now());
          }
          next.whenData((page) {
            ref
                .read(treinosDoAlunoTailProvider(widget.alunoId!).notifier)
                .reset(hasNext: page.hasNext);
          });
        },
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final pageTreinos = treinosAsync.valueOrNull ?? const <Treino>[];
    final loadedTreinos = [...pageTreinos, ...tail.treinos];
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fromAluno = widget.alunoId != null;
    final title =
        widget.alunoId == null
            ? 'Treinos'
            : (widget.alunoNome == null || widget.alunoNome!.trim().isEmpty)
            ? 'Treinos do aluno'
            : 'Treinos de ${widget.alunoNome!.trim()}';

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
        invalidateTreinosDoAluno(ref, widget.alunoId!);
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
      child: PopScope(
        canPop:
            !keyboardOpen &&
            !_selectionMode &&
            !fromAluno,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocusNode.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          if (_selectionMode) {
            _clearSelection();
            return;
          }
          if (fromAluno) {
            safePopOrGo(context, '/alunos/${widget.alunoId}');
          }
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: title,
            subtitle:
                _selectionMode
                    ? TreinosListLabels.selectionCount(_selectedIds.length)
                    : TreinosListLabels.listSubtitle(
                      count:
                          fromLibrary
                              ? (homeBundle?.totalElements ??
                                  homeBundle?.resumo.totalPlanos ??
                                  loadedTreinos.length)
                              : (alunoPageAsync?.valueOrNull?.totalElements ??
                                  loadedTreinos.length),
                      freshness: freshnessLabel,
                    ),
            showBack: fromAluno,
            onBack:
                fromAluno
                    ? () {
                      FxKeyboardDismissScope.dismiss();
                      safePopOrGo(context, '/alunos/${widget.alunoId}');
                    }
                    : null,
            fallbackLocation:
                fromAluno ? '/alunos/${widget.alunoId}' : null,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar os treinos',
                onTap: _openHelp,
              ),
              IconButton(
                tooltip:
                    _selectionMode
                        ? 'Cancelar seleção'
                        : 'Selecionar treinos',
                onPressed:
                    loadedTreinos.isEmpty
                        ? null
                        : () {
                          if (_selectionMode) {
                            _clearSelection();
                            return;
                          }
                          setState(() {
                            _selectionMode = true;
                            _selectedIds
                              ..clear()
                              ..addAll(
                                loadedTreinos
                                    .where(_matchesQuery)
                                    .map((treino) => treino.id),
                              );
                          });
                        },
                icon: Icon(
                  _selectionMode
                      ? Icons.close_rounded
                      : Icons.checklist_rounded,
                ),
              ),
            ],
          ),
          body: treinosAsync.when(
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
              final filteredTreinos =
                  fromLibrary
                      ? loadedTreinos
                      : loadedTreinos.where(_matchesQuery).toList();
              final selectedTreinos =
                  loadedTreinos
                      .where((treino) => _selectedIds.contains(treino.id))
                      .toList();
              final singlePlan = loadedTreinos.length == 1;
              final createLabel =
                  widget.alunoId == null
                      ? (uiHints?.createCtaLabel ?? 'Criar treino')
                      : 'Criar treino';
              final pinCreateInScroll =
                  !_selectionMode &&
                  filteredTreinos.isNotEmpty &&
                  filteredTreinos.length <= 5 &&
                  !tail.hasNext;
              final showStickyCreate =
                  !_selectionMode &&
                  (loadedTreinos.isEmpty ||
                      (loadedTreinos.isNotEmpty && !pinCreateInScroll));
              final sparseHint =
                  pinCreateInScroll
                      ? null
                      : treinosSparseHint(count: filteredTreinos.length);
              final listBottom = treinosListBottomPad(
                context: context,
                stickyVisible: showStickyCreate,
              );
              final mute =
                  isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: refresh,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.extentAfter < 480 &&
                              tail.hasNext &&
                              !tail.loading) {
                            if (fromLibrary) {
                              ref.read(treinosHomeTailProvider.notifier).loadMore(
                                query: ref.read(treinosHomeQueryProvider),
                                repo: ref.read(treinoRepositoryProvider),
                              );
                            } else {
                              ref
                                  .read(
                                    treinosDoAlunoTailProvider(
                                      widget.alunoId!,
                                    ).notifier,
                                  )
                                  .loadMoreAluno(
                                    alunoId: widget.alunoId!,
                                    query: ref.read(
                                      treinosDoAlunoQueryProvider(
                                        widget.alunoId!,
                                      ),
                                    ),
                                    repo: ref.read(treinoRepositoryProvider),
                                  );
                            }
                          }
                          return false;
                        },
                        child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (loadedTreinos.isEmpty && _query.trim().isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  TreinosLayout.screenPadding,
                                  8,
                                  TreinosLayout.screenPadding,
                                  8,
                                ),
                                child: Center(
                                  child: FxEmptyState(
                                    icon: 'dumbbell',
                                    title:
                                        widget.alunoId == null
                                            ? (uiHints?.emptyTitle ??
                                                TreinosListLabels.emptyTitle(
                                                  alunoNome: widget.alunoNome,
                                                ))
                                            : TreinosListLabels.emptyTitle(
                                              alunoNome: widget.alunoNome,
                                            ),
                                    subtitle:
                                        widget.alunoId == null
                                            ? (uiHints?.emptySubtitle ??
                                                TreinosListLabels.emptySubtitle(
                                                  alunoNome: widget.alunoNome,
                                                ))
                                            : TreinosListLabels.emptySubtitle(
                                              alunoNome: widget.alunoNome,
                                            ),
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
                                    focusNode: _searchFocusNode,
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
                                                      homeBundle?.resumo.prontos ??
                                                      loadedTreinos
                                                          .where((t) => t.pronto)
                                                          .length,
                                                  exercises:
                                                      homeBundle
                                                          ?.resumo
                                                          .totalExercicios ??
                                                      loadedTreinos.fold<int>(
                                                        0,
                                                        (sum, t) =>
                                                            sum +
                                                            t.exerciciosCount,
                                                      ),
                                                ))
                                            : TreinosListLabels.countLabel(
                                              homeBundle?.totalElements ??
                                                  filteredTreinos.length,
                                            ),
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
                                      widget.alunoId == null
                                          ? 'Ajuste a busca para encontrar outro treino da biblioteca.'
                                          : 'Ajuste a busca para encontrar outro treino do aluno.',
                                  action: FxEmptyAction(
                                    label: 'Limpar busca',
                                    onTap: _clearQuery,
                                  ),
                                ),
                              )
                            else
                              ...[
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    TreinosLayout.screenPadding,
                                    _selectionMode ? 4 : 0,
                                    TreinosLayout.screenPadding,
                                    sparseHint == null ? listBottom : TokensStrip.s2,
                                  ),
                                  sliver: SliverList.separated(
                                    itemCount:
                                        filteredTreinos.length +
                                        (tail.hasNext ? 1 : 0),
                                    separatorBuilder:
                                        (_, __) => const SizedBox(
                                          height: TokensStrip.s2,
                                        ),
                                    itemBuilder: (context, i) {
                                      if (i >= filteredTreinos.length) {
                                        return const SizedBox(height: 48);
                                      }
                                      return _TreinoCard(
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
                                      );
                                    },
                                  ),
                                ),
                                if (sparseHint != null)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        TreinosLayout.screenPadding,
                                        TokensStrip.s2,
                                        TreinosLayout.screenPadding,
                                        listBottom,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 16,
                                            color: mute,
                                          ),
                                          const SizedBox(
                                            width: TokensStrip.s2,
                                          ),
                                          Expanded(
                                            child: Text(
                                              sparseHint,
                                              style:
                                                  FocuxHubTypography.bodyMuted(
                                                    color: mute,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.35,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (pinCreateInScroll)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        TreinosLayout.screenPadding,
                                        TokensStrip.s2,
                                        TreinosLayout.screenPadding,
                                        listBottom,
                                      ),
                                      child: FxLiquidPrimaryButton(
                                        label: createLabel,
                                        onPressed: createWorkout,
                                      ),
                                    ),
                                  ),
                              ],
                          ],
                        ],
                      ),
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
                    )
                  else if (showStickyCreate)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TreinosLayout.screenPadding,
                          TokensStrip.s2,
                          TreinosLayout.screenPadding,
                          TokensStrip.s2 +
                              MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: FxLiquidPrimaryButton(
                          label: createLabel,
                          onPressed: createWorkout,
                        ),
                      ),
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
