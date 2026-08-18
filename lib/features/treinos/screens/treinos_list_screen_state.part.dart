part of 'treinos_list_screen.dart';

class _TreinosListViewState extends ConsumerState<_TreinosListView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  String _query = '';
  bool _selectionMode = false;
  DateTime? _fetchedAt;

  @override
  void dispose() {
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
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  Future<void> _assignTreino(Treino treino) async {
    try {
      final alunos = await ref.read(alunosProvider.future);
      if (!mounted) return;
      final selected = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.34),
        isScrollControlled: true,
        useRootNavigator: true,
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
      final selected = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.34),
        isScrollControlled: true,
        useRootNavigator: true,
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
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível copiar o treino.'),
      );
    }
  }

  Future<void> _openTreinoActions(Treino treino) async {
    final action = await showModalBottomSheet<_TreinoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      useRootNavigator: true,
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
        await _deleteTreinos([treino]);
        break;
    }
  }

  Future<void> _deleteTreinos(List<Treino> treinos) async {
    if (treinos.isEmpty) return;
    final count = treinos.length;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
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
    ref.listen<AsyncValue<List<Treino>>>(treinosSource, (_, next) {
      if (!next.isLoading && next.hasValue) {
        setState(() => _fetchedAt = DateTime.now());
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    Future<void> refresh() async {
      if (widget.alunoId == null) {
        invalidateTreinosCaches(ref);
      } else {
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
    }

    Future<void> createWorkout() async {
      final criado = await context.push<bool>(
        '/treinos/novo',
        extra:
            widget.alunoId == null
                ? null
                : {'alunoId': widget.alunoId, 'alunoNome': widget.alunoNome},
      );
      if (criado == true) {
        await refresh();
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
              final filteredTreinos = treinos.where(_matchesQuery).toList();
              final selectedTreinos =
                  treinos
                      .where((treino) => _selectedIds.contains(treino.id))
                      .toList();
              final singlePlan = treinos.length == 1;

              return RefreshIndicator(
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
                        onHelp: () => showTreinosListHelpSheet(context),
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
                        child: FxEmptyState(
                          icon: 'dumbbell',
                          title: TreinosListLabels.emptyTitle(
                            alunoNome: widget.alunoNome,
                          ),
                          subtitle: TreinosListLabels.emptySubtitle(
                            alunoNome: widget.alunoNome,
                          ),
                          action: FxEmptyAction(
                            label: 'Criar treino',
                            onTap: createWorkout,
                          ),
                        ),
                      )
                    else ...[
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
                            selectionMode: _selectionMode,
                            isDark: isDark,
                            primary: primary,
                            onQueryChanged:
                                (value) => setState(() => _query = value),
                            onClearQuery: _clearQuery,
                            onDeleteSelected:
                                selectedTreinos.isEmpty
                                    ? null
                                    : () => _deleteTreinos(selectedTreinos),
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
                                    ? TreinosListLabels.libraryCaption(
                                      prontos:
                                          treinos.where((t) => t.pronto).length,
                                      exercises: treinos.fold<int>(
                                        0,
                                        (sum, t) => sum + t.exerciciosCount,
                                      ),
                                    )
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
                          padding: const EdgeInsets.fromLTRB(
                            TreinosLayout.screenPadding,
                            0,
                            TreinosLayout.screenPadding,
                            104,
                          ),
                          sliver: SliverList.separated(
                            itemCount: filteredTreinos.length,
                            separatorBuilder:
                                (_, __) => SizedBox(height: TokensStrip.s3),
                            itemBuilder:
                                (context, i) => FxStaggerItem(
                                  index: i,
                                  child: _TreinoCard(
                                    treino: filteredTreinos[i],
                                    index: i,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
