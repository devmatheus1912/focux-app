part of 'treinos_list_screen.dart';

class _TreinosListViewState extends ConsumerState<_TreinosListView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  String _query = '';
  bool _selectionMode = false;

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
      '${treino.exercicios.length} exercicios',
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

  Future<void> _assignTreino(Treino treino) async {
    try {
      final alunos = await ref.read(alunosProvider.future);
      if (!mounted) return;
      final selected = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.34),
        isScrollControlled: true,
        builder: (_) => _AssignWorkoutSheet(alunos: alunos),
      );
      if (selected == null) return;

      await ref
          .read(treinoRepositoryProvider)
          .atribuirAluno(treino.id, selected);
      ref.invalidate(treinosProvider);
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
      ref.invalidate(treinosProvider);
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
        builder: (_) => _AssignWorkoutSheet(alunos: alunos),
      );
      if (selected == null) return;

      await ref
          .read(treinoRepositoryProvider)
          .clonarParaAluno(treino.id, selected);
      ref.invalidate(treinosProvider);
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
        ref.invalidate(treinosProvider);
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
    final treinosAsync =
        widget.alunoId == null
            ? ref.watch(treinosProvider)
            : ref.watch(treinosDoAlunoProvider(widget.alunoId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    Future<void> refresh() async {
      if (widget.alunoId == null) {
        ref.invalidate(treinosProvider);
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

    return Scaffold(
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
              (e, _) => _TreinosErrorState(
                isDark: isDark,
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
                      treinos: treinos,
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                      isDark: isDark,
                      onBack:
                          widget.alunoId == null
                              ? null
                              : () => safePopOrGo(
                                context,
                                '/alunos/${widget.alunoId}',
                              ),
                    ),
                  ),
                  if (treinos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        isDark: isDark,
                        primary: primary,
                        alunoNome: widget.alunoNome,
                        onCreate: createWorkout,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          singlePlan ? 12 : 16,
                        ),
                        child: _TreinosCommandCard(
                          treinos: treinos,
                          isDark: isDark,
                          primary: primary,
                          compact: treinos.length <= 2,
                          onCreate: createWorkout,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          singlePlan ? 12 : 14,
                        ),
                        child: _LibraryControls(
                          controller: _searchController,
                          query: _query,
                          selectedCount: _selectedIds.length,
                          selectionMode: _selectionMode,
                          isDark: isDark,
                          primary: primary,
                          onQueryChanged:
                              (value) => setState(() => _query = value),
                          onClearQuery:
                              () => setState(() {
                                _query = '';
                                _searchController.clear();
                              }),
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
                          onDeleteSelected:
                              selectedTreinos.isEmpty
                                  ? null
                                  : () => _deleteTreinos(selectedTreinos),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          12,
                        ),
                        child: _SectionHeader(
                          title:
                              widget.alunoId == null
                                  ? 'Biblioteca ativa'
                                  : 'Plano do aluno',
                          action:
                              _query.trim().isEmpty
                                  ? '${treinos.length} ${treinos.length == 1 ? 'plano' : 'planos'}'
                                  : '${filteredTreinos.length} de ${treinos.length}',
                          isDark: isDark,
                        ),
                      ),
                    ),
                    if (filteredTreinos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResultsState(
                          isDark: isDark,
                          primary: primary,
                          onClear:
                              () => setState(() {
                                _query = '';
                                _searchController.clear();
                              }),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
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
    );
  }
}
