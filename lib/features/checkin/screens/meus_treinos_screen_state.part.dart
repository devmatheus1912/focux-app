part of 'meus_treinos_screen.dart';

String meusTreinosCountLabel(int count) {
  if (count <= 0) return 'Nenhum treino';
  if (count == 1) return '1 treino';
  return '$count treinos';
}

/// Insight quieto do job Treinos — espelha ritmo da Home sem score numérico.
String _treinosInsightLine({
  required List<ExecucaoTreino> historico,
  required int startableCount,
}) {
  final days = countUniqueCompletedDaysThisWeek(historico);
  if (days >= 3) return 'Ritmo forte · mantenha o volume';
  if (days >= 1) return 'Ritmo construindo · complete a semana';
  if (startableCount > 0) return 'Hora de treinar · plano pronto';
  return 'Consistência em retomada';
}

class _MeusTreinosScreenState extends ConsumerState<MeusTreinosScreen> {
  DateTime? _fetchedAt;
  int? _startingTreinoId;
  int? _confirmingTreinoId;
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

  Future<void> _confirmarPlano(ExecucaoTreino treino) async {
    if (_confirmingTreinoId != null || _startingTreinoId != null) return;
    setState(() => _confirmingTreinoId = treino.treinoId);
    try {
      await ref.read(checkinRepositoryProvider).confirmarPlano(treino.treinoId);
      MeusTreinosMemCache.clear();
      EvolucaoHomeClientCache.clear();
      Aluno360ClientCache.clear();
      ref.invalidate(historicoCheckinProvider);
      ref.invalidate(meusTreinosProvider);
      ref.invalidate(alunoDashboardHomeProvider);
      if (!mounted) return;
      await FxCelebrationOverlay.show(
        context,
        title: 'Treino registrado',
        subtitle: 'Sequência conta a semana, não o dia. Descanso não zera.',
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted && _confirmingTreinoId == treino.treinoId) {
        setState(() => _confirmingTreinoId = null);
      }
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
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final homeAsync = ref.watch(alunoDashboardHomeProvider);
    final home = homeAsync.valueOrNull;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final base = treinosAsync.valueOrNull?.content ?? const <ExecucaoTreino>[];
    final treinos = [...base, ..._extra];
    final count =
        treinosAsync.hasValue
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
              TextButton(
                onPressed: () => context.push('/checkin/historico'),
                child: Text(
                  'Histórico',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                  final itemCount =
                      ordered.length +
                      (_hasMore || _loadMoreError != null ? 1 : 0);
                  final sessaoAberta = treinoSessaoEmAndamento(ordered);

                  return RefreshIndicator(
                    color: primary,
                    onRefresh: () async => ref.invalidate(meusTreinosProvider),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),
                        if (sessaoAberta != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s5,
                                0,
                                20,
                                8,
                              ),
                              child: _RetomarTreinoBanner(
                                treino: sessaoAberta,
                                isDark: isDark,
                                onRetomar: () => context.push(
                                  '/checkin/executar',
                                  extra: sessaoAberta.treinoId,
                                ),
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
                            child:
                                home != null
                                    ? ProgressoSemanalWidget(
                                      treinos: home.treinos,
                                      historico: home.historico,
                                      aderenciaPercent:
                                          home.aluno.aderenciaPercent,
                                      volumeSemanaKg:
                                          home.volumeSemanaKg > 0
                                              ? home.volumeSemanaKg
                                              : null,
                                      insight: _treinosInsightLine(
                                        historico: home.historico,
                                        startableCount: startableCount,
                                      ),
                                    )
                                    : _WeekProgressStrip(
                                      ativos: ativos,
                                      startableCount: startableCount,
                                      total: ordered.length,
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
                                confirming:
                                    _confirmingTreinoId ==
                                    ordered[index].treinoId,
                                onConfirmPlano:
                                    () => _confirmarPlano(ordered[index]),
                                onStart: () {
                                  final treino = ordered[index];
                                  if (_startingTreinoId != null ||
                                      _confirmingTreinoId != null) {
                                    return;
                                  }
                                  final aberta = treinoSessaoEmAndamento(
                                    ordered,
                                  );
                                  if (aberta != null &&
                                      aberta.treinoId != treino.treinoId) {
                                    FeedbackHelper.showInfo(
                                      context,
                                      'Retome "${aberta.treinoNome}" ou descarte a sessão antes de iniciar outro treino.',
                                    );
                                    return;
                                  }
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
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 110),
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
