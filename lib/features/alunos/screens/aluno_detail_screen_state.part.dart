part of 'aluno_detail_screen.dart';

class _AlunoDetailScreenState extends ConsumerState<AlunoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _entrancePlayed = false;
  String? _lastFocusSyncSignature;

  int get alunoId => widget.alunoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    final tab = widget.initialTabIndex;
    if (tab != null && tab >= 0 && tab < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != tab) {
          _tabController.index = tab;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aluno360Async = ref.watch(aluno360Provider(alunoId));
    // First paint: only /360. Watch GET /alunos/{id} solely when 360 failed.
    final alunoFallbackAsync =
        shouldWatchAlunoDetailFallback(aluno360Async)
            ? ref.watch(alunoProvider(alunoId))
            : null;
    final tabIndex = _tabController.index;
    final autonomiaResumoAsync =
        tabIndex == 0 && !aluno360Async.hasValue
            ? ref.watch(alunoAutonomiaResumoProvider(alunoId))
            : const AsyncValue<AlunoAutonomiaResumo>.loading();
    final watchTab1Sidecars = shouldWatchAluno360Tab1Sidecars(
      aluno360Async,
      tabIndex: tabIndex,
    );
    final evolucaoGranularAsync =
        watchTab1Sidecars
            ? ref.watch(alunoEvolucaoInteligenteProvider(alunoId))
            : const AsyncValue<EvolucaoInteligente>.loading();
    final timelineGranularAsync =
        watchTab1Sidecars
            ? ref.watch(alunoTimeline360ApiProvider(alunoId))
            : const AsyncValue<List<Timeline360Event>>.loading();
    final bundledRecovery = aluno360Async.valueOrNull?.recoverySnapshot;
    final AsyncValue<RecoverySnapshot?> recoveryAsync;
    if (tabIndex != 0) {
      recoveryAsync = const AsyncValue.data(null);
    } else if (bundledRecovery != null) {
      recoveryAsync = AsyncValue.data(bundledRecovery);
    } else if (shouldWatchAlunoRecoverySidecar(
      aluno360Async,
      tabIndex: tabIndex,
    )) {
      recoveryAsync = ref.watch(alunoRecoveryProvider(alunoId));
    } else {
      recoveryAsync = const AsyncValue.loading();
    }
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;

    final resolvedAlunoAsync = resolveAlunoDetailAlunoAsync(
      aluno360Async: aluno360Async,
      alunoFallbackAsync: alunoFallbackAsync,
    );

    AsyncValue<AlunoAutonomiaResumo> resolvedAutonomiaResumoAsync =
        autonomiaResumoAsync;
    if (aluno360Async.hasValue) {
      resolvedAutonomiaResumoAsync = AsyncData(
        aluno360Async.value!.autonomiaResumo,
      );
    }

    AsyncValue<EvolucaoInteligente> resolvedEvolucaoAsync =
        aluno360Async.hasValue
            ? AsyncData(aluno360Async.value!.evolucaoInteligente)
            : evolucaoGranularAsync;

    AsyncValue<List<Timeline360Event>> resolvedTimelineAsync =
        aluno360Async.hasValue
            ? AsyncData(aluno360Async.value!.timelinePreview)
            : timelineGranularAsync;

    final loadingPrimary = aluno360Async.isLoading && !aluno360Async.hasValue;
    final loadingFallback =
        resolvedAlunoAsync.isLoading && !resolvedAlunoAsync.hasValue;

    final proximaAcao360 = aluno360Async.valueOrNull?.proximaAcao;
    final showOperacaoSticky =
        _tabController.index == 0 && resolvedAlunoAsync.hasValue;

    return fxScreenA11yScope(
      label: 'Aluno Detail',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            loadingPrimary || loadingFallback
                ? AlunoDetailLoadingSkeleton(
                  tabController: _tabController,
                  isDark: isDark,
                  primary: primary,
                  ink: ink,
                  mute: mute,
                  line: chrome.line,
                  sheetFill: chrome.sheetFill,
                )
                : resolvedAlunoAsync.when(
                  loading:
                      () => AlunoDetailLoadingSkeleton(
                        tabController: _tabController,
                        isDark: isDark,
                        primary: primary,
                        ink: ink,
                        mute: mute,
                        line: chrome.line,
                        sheetFill: chrome.sheetFill,
                      ),
                  error:
                      (e, _) => FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        message: friendlyError(
                          aluno360Async.error ?? e,
                          fallback:
                              'Não foi possível carregar os dados do aluno.',
                        ),
                        onRetry: () {
                          invalidateAluno360Providers(ref, alunoId);
                        },
                        title: 'Não conseguimos carregar o aluno',
                      ),
                  data: (aluno) {
                    final perfilCompletion = copilotProfileCompletion(aluno);
                    final operacao = ref.watch(
                      aluno360OperacaoProvider(alunoId),
                    );
                    final compactHero =
                        operacao?.contactPriority ??
                        isOperacaoContatoPrioritario(aluno: aluno);
                    final topInset = MediaQuery.paddingOf(context).top;
                    final heroBodyHeight = Aluno360Layout.heroBodyHeight(
                      context,
                      compactContactPriority: compactHero,
                    );
                    final displayName = fxTitleCaseName(aluno.nome);
                    final contactPriority =
                        operacao?.contactPriority ??
                        isOperacaoContatoPrioritario(aluno: aluno);

                    final focusSignature =
                        '${aluno.id}|${aluno.operacaoFocusMode}|$contactPriority|'
                        '${aluno.emRisco}|${aluno.aderenciaPercent}';
                    if (_lastFocusSyncSignature != focusSignature) {
                      _lastFocusSyncSignature = focusSignature;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ref
                            .read(
                              alunoOperacaoFocusModeProvider(alunoId).notifier,
                            )
                            .syncFromAluno(
                              aluno,
                              autoDefault: shouldDefaultOperacaoFocusMode(
                                aluno: aluno,
                                contactPriority: contactPriority,
                              ),
                            );
                      });
                    }

                    return RefreshIndicator(
                      onRefresh:
                          () => invalidateAluno360Providers(ref, alunoId),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: Aluno360CompositeHeaderDelegate(
                              topInset: topInset,
                              heroBodyHeight: heroBodyHeight,
                              heroChild: AlunoDetailHeroCard(
                                aluno: aluno,
                                isDark: isDark,
                                primary: primary,
                                compactContactPriority: compactHero,
                                onDefineObjective:
                                    alunoObjectiveIsDefined(aluno.objetivo)
                                        ? null
                                        : () async {
                                          final updated = await context
                                              .push<bool>(
                                                '/alunos/$alunoId/editar',
                                                extra: aluno,
                                              );
                                          if (updated == true) {
                                            invalidateAluno360Providers(
                                              ref,
                                              alunoId,
                                            );
                                          }
                                        },
                              ),
                              tabController: _tabController,
                              primary: primary,
                              mute: mute,
                              line: chrome.line,
                              displayName: displayName,
                              ink: ink,
                              isDark: isDark,
                              onBack: () => safePopOrGo(context, '/alunos'),
                              onDelete:
                                  () => confirmarExclusaoAlunoDetail(
                                    context,
                                    ref,
                                    aluno,
                                  ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: Aluno360Layout.tabContentGap,
                                left: Aluno360Layout.screenPadding,
                                right: Aluno360Layout.screenPadding,
                                bottom:
                                    showOperacaoSticky
                                        ? Aluno360Layout.operacaoScrollBottomReserve(
                                          context,
                                        )
                                        : MediaQuery.paddingOf(context).bottom +
                                            8,
                              ),
                              child: AnimatedSwitcher(
                                duration:
                                    reduceMotionOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  if (reduceMotionOf(context)) return child;
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.015),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: switch (tabIndex) {
                                  0 => Aluno360DetailOperacaoTab(
                                    key: const ValueKey(
                                      'aluno360_tab_operacao',
                                    ),
                                    aluno: aluno,
                                    alunoId: alunoId,
                                    isDark: isDark,
                                    primary: primary,
                                    proximaAcao360: proximaAcao360,
                                    hasOpenCopilotTask360:
                                        aluno360Async
                                            .valueOrNull
                                            ?.hasOpenCopilotTask ??
                                        false,
                                    aderenciaSemanal:
                                        aluno360Async
                                            .valueOrNull
                                            ?.aderenciaSemanal
                                            .dias,
                                    recoveryAsync: recoveryAsync,
                                    autonomiaResumoAsync:
                                        resolvedAutonomiaResumoAsync,
                                    animateEntrance: !_entrancePlayed,
                                    onEntrancePlayed: () {
                                      if (!_entrancePlayed) {
                                        setState(() => _entrancePlayed = true);
                                      }
                                    },
                                    onPassword:
                                        () => confirmarGerarSenhaAlunoDetail(
                                          context,
                                          ref,
                                          aluno,
                                        ),
                                    onEdit: () async {
                                      final updated = await context.push<bool>(
                                        '/alunos/$alunoId/editar',
                                        extra: aluno,
                                      );
                                      if (updated == true) {
                                        invalidateAluno360Providers(
                                          ref,
                                          alunoId,
                                        );
                                      }
                                    },
                                    onEvolve:
                                        () => context.push(
                                          '/alunos/${aluno.id}/ia/progressao',
                                          extra: aluno.nome,
                                        ),
                                  ),
                                  1 => Aluno360DetailEvolucaoTab(
                                    key: const ValueKey(
                                      'aluno360_tab_evolucao',
                                    ),
                                    aluno: aluno,
                                    alunoId: alunoId,
                                    isDark: isDark,
                                    ink: ink,
                                    evolucaoAsync: resolvedEvolucaoAsync,
                                    timeline360Async: resolvedTimelineAsync,
                                    animateEntrance: !_entrancePlayed,
                                    onEntrancePlayed: () {
                                      if (!_entrancePlayed) {
                                        setState(() => _entrancePlayed = true);
                                      }
                                    },
                                    onOpenCopilot:
                                        () => _tabController.animateTo(0),
                                  ),
                                  _ => Aluno360DetailFerramentasTab(
                                    key: const ValueKey(
                                      'aluno360_tab_ferramentas',
                                    ),
                                    aluno: aluno,
                                    alunoId: alunoId,
                                    isDark: isDark,
                                    primary: primary,
                                    perfilCompletion: perfilCompletion,
                                    animateEntrance: !_entrancePlayed,
                                    onEntrancePlayed: () {
                                      if (!_entrancePlayed) {
                                        setState(() => _entrancePlayed = true);
                                      }
                                    },
                                  ),
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            if (showOperacaoSticky)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Aluno360OperacaoStickyCtaBar(
                  aluno: resolvedAlunoAsync.value!,
                  alunoId: alunoId,
                  proximaAcao360: proximaAcao360,
                  hasOpenCopilotTask360:
                      aluno360Async.valueOrNull?.hasOpenCopilotTask ?? false,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
