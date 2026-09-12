part of 'meus_treinos_screen.dart';

String meusTreinosCountLabel(int count) {
  if (count <= 0) return 'Nenhum treino';
  if (count == 1) return '1 treino';
  return '$count treinos';
}

class _MeusTreinosScreenState extends ConsumerState<MeusTreinosScreen> {
  DateTime? _fetchedAt;
  int? _startingTreinoId;
  final List<ExecucaoTreino> _extra = [];
  var _page = 0;
  var _hasMore = false;
  var _loadingMore = false;
  String? _loadMoreError;

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final next = await ref
          .read(checkinRepositoryProvider)
          .meusTreinosPagina(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _extra.addAll(next.content);
        _page = next.page ?? (_page + 1);
        _hasMore = next.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = friendlyError(
          e,
          fallback: 'Não foi possível carregar mais treinos.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    ref.listen<AsyncValue<Pagina<ExecucaoTreino>>>(meusTreinosProvider, (
      _,
      next,
    ) {
      next.whenData((pagina) {
        if (!mounted) return;
        setState(() {
          _extra.clear();
          _page = pagina.page ?? 0;
          _hasMore = pagina.hasNext;
          _loadMoreError = null;
          _fetchedAt = DateTime.now();
        });
      });
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final base = treinosAsync.valueOrNull?.content ?? const <ExecucaoTreino>[];
    final treinos = [...base, ..._extra];
    final count = treinosAsync.hasValue
        ? (treinosAsync.value!.totalElements ?? treinos.length)
        : treinos.length;

    return fxScreenA11yScope(
      label: 'Sua rotina',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Sua rotina',
            subtitle: FxHubFreshness.joinCount(
              meusTreinosCountLabel(count),
              treinosAsync.isLoading && base.isEmpty ? null : freshnessLabel,
            ),
            showBack: false,
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(meusTreinosProvider),
                icon: Icon(Icons.refresh_rounded, color: chrome.mute),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: FxContentWidthLimiter(
              child: FxAsyncBody<Pagina<ExecucaoTreino>>(
                value: treinosAsync,
                onRetry: () => ref.invalidate(meusTreinosProvider),
                chromeOnDark: isDark,
                primary: primary,
                errorTitle: FocuxMicrocopy.naoFoiPossivelCarregar,
                skeleton: const _TrainingSkeleton(),
                isEmpty: (pagina) => pagina.content.isEmpty,
                empty: FxEmptyState(
                  icon: 'dumbbell',
                  title: 'Nenhum treino atribuído',
                  subtitle:
                      'Assim que seu personal liberar um treino, ele aparece aqui com execução guiada.',
                  action: FxEmptyAction(
                    label: 'Atualizar',
                    onTap: () => ref.invalidate(meusTreinosProvider),
                  ),
                ),
                builder: (context, _) {
                  final ordered = treinosOrdenadosStartFirst(treinos);
                  final ativos =
                      ordered
                          .where((t) => t.status.toUpperCase() != 'CONCLUIDO')
                          .length;
                  final startableCount =
                      ordered.where(isTreinoDisponivelParaIniciar).length;
                  final hasStartable = startableCount > 0;
                  final totalExercicios = ordered.fold<int>(
                    0,
                    (sum, t) => sum + t.exercicios.length,
                  );
                  final totalConcluidos = ordered.fold<int>(
                    0,
                    (sum, t) =>
                        sum + t.exercicios.where((e) => e.concluido).length,
                  );
                  final itemCount =
                      ordered.length +
                      (_hasMore || _loadMoreError != null ? 1 : 0);

                  return RefreshIndicator(
                    color: primary,
                    onRefresh: () async => ref.invalidate(meusTreinosProvider),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s5,
                              0,
                              20,
                              12,
                            ),
                            child: _TrainingHero(
                              ativos: ativos,
                              startableCount: startableCount,
                              total: ordered.length,
                              totalExercicios: totalExercicios,
                              totalConcluidos: totalConcluidos,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s5,
                            0,
                            20,
                            10,
                          ),
                          sliver: SliverList.separated(
                            itemCount: itemCount,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index >= ordered.length) {
                                if (_loadMoreError != null) {
                                  return TextButton(
                                    onPressed: _loadMore,
                                    child: Text(_loadMoreError!),
                                  );
                                }
                                return TextButton(
                                  onPressed: _loadingMore ? null : _loadMore,
                                  child: Text(
                                    _loadingMore
                                        ? 'Carregando…'
                                        : 'Carregar mais',
                                  ),
                                );
                              }
                              return _TrainingPlanCard(
                                treino: ordered[index],
                                isDark: isDark,
                                starting:
                                    _startingTreinoId ==
                                    ordered[index].treinoId,
                                onStart: () {
                                  final treino = ordered[index];
                                  if (_startingTreinoId != null) return;
                                  setState(
                                    () => _startingTreinoId = treino.treinoId,
                                  );
                                  context.push(
                                    '/checkin/executar',
                                    extra: treino.treinoId,
                                  );
                                  Future<void>.delayed(
                                    const Duration(milliseconds: 600),
                                    () {
                                      if (!mounted) return;
                                      if (_startingTreinoId ==
                                          treino.treinoId) {
                                        setState(
                                          () => _startingTreinoId = null,
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s5,
                              0,
                              20,
                              110,
                            ),
                            child: _TrainingReadinessSection(
                              totalExercicios: totalExercicios,
                              totalConcluidos: totalConcluidos,
                              ativos: ativos,
                              hasStartable: hasStartable,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
