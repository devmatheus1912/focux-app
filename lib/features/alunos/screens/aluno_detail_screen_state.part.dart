part of 'aluno_detail_screen.dart';

class _AlunoDetailScreenState extends ConsumerState<AlunoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _entrancePlayed = false;
  DateTime? _fetchedAt;
  late final DateTime _openedAt;
  bool _loggedFirstPaint = false;
  bool _secondaryPrefetchScheduled = false;
  final Set<int> _openedTabs = {0};

  int get alunoId => widget.alunoId;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _openedTabs.add(_tabController.index);
        setState(() {});
      }
    });
    final tab = widget.initialTabIndex;
    if (tab != null && tab >= 0 && tab < 3) {
      _openedTabs.add(tab);
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

  void _markFetched() {
    if (!mounted) return;
    setState(() => _fetchedAt = DateTime.now());
  }

  Future<void> _reload360() async {
    await invalidateAluno360Providers(ref, alunoId);
    _markFetched();
  }

  @override
  Widget build(BuildContext context) {
    final listPreview = resolveAlunoDetailListPreview(
      alunoId: alunoId,
      routePreview: widget.listPreview,
    );
    final operacaoAsync = ref.watch(aluno360OperacaoBundleProvider(alunoId));
    // First paint: ONLY /360/operacao. Never monolito /360. Never IA.
    final alunoFallbackAsync =
        shouldWatchAlunoDetailFallback(operacaoAsync)
            ? ref.watch(alunoProvider(alunoId))
            : null;
    final tabIndex = _tabController.index;
    final evolucaoTabOpened = _openedTabs.contains(1);
    final ferramentasTabOpened = _openedTabs.contains(2);

    // Prefetch secondary tabs after Operação is usable (idle priority).
    if (operacaoAsync.hasValue && !_secondaryPrefetchScheduled) {
      _secondaryPrefetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SchedulerBinding.instance.scheduleTask(() {
          if (!mounted) return;
          prefetchAluno360SecondaryTabs(ref, alunoId);
        }, Priority.idle);
      });
    }

    // Evolução: watch on tab open or after prefetch kickoff.
    final AsyncValue<Aluno360Evolucao> evolucaoAsync;
    if (evolucaoTabOpened || _secondaryPrefetchScheduled) {
      evolucaoAsync = ref.watch(aluno360EvolucaoBundleProvider(alunoId));
    } else {
      evolucaoAsync = const AsyncValue<Aluno360Evolucao>.loading();
    }

    // Ferramentas prefetch (payload optional — modules still use own providers).
    if (ferramentasTabOpened || _secondaryPrefetchScheduled) {
      ref.watch(aluno360FerramentasBundleProvider(alunoId));
    }

    // Warm Medidas hub while user is on Ferramentas (kills ~3s cold open).
    if (ferramentasTabOpened) {
      prefetchEvolucaoHome(ref, alunoId);
    }

    final watchTab1Sidecars = shouldWatchAluno360Tab1Sidecars(
      evolucaoAsync,
      tabIndex: tabIndex,
      evolucaoTabOpened: evolucaoTabOpened,
    );
    final evolucaoGranularAsync =
        watchTab1Sidecars
            ? ref.watch(alunoEvolucaoInteligenteProvider(alunoId))
            : const AsyncValue<EvolucaoInteligente>.loading();
    final timelineGranularAsync =
        watchTab1Sidecars
            ? ref.watch(alunoTimeline360ApiProvider(alunoId))
            : const AsyncValue<List<Timeline360Event>>.loading();

    // Autonomia from /360/operacao only — never sidecar on first paint.
    final autonomiaResumoAsync =
        const AsyncValue<AlunoAutonomiaResumo>.loading();

    final bundledRecovery = operacaoAsync.valueOrNull?.recoverySnapshot;
    final AsyncValue<RecoverySnapshot?> recoveryAsync;
    if (tabIndex != 0) {
      recoveryAsync = const AsyncValue.data(null);
    } else if (bundledRecovery != null) {
      recoveryAsync = AsyncValue.data(bundledRecovery);
    } else if (shouldWatchAlunoRecoverySidecar(
      operacaoAsync,
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
      operacaoAsync: operacaoAsync,
      alunoFallbackAsync: alunoFallbackAsync,
    );

    AsyncValue<AlunoAutonomiaResumo> resolvedAutonomiaResumoAsync =
        autonomiaResumoAsync;
    if (operacaoAsync.hasValue) {
      resolvedAutonomiaResumoAsync = AsyncData(
        operacaoAsync.value!.autonomiaResumo,
      );
    }

    AsyncValue<EvolucaoInteligente> resolvedEvolucaoAsync =
        evolucaoAsync.hasValue
            ? AsyncData(evolucaoAsync.value!.evolucaoInteligente)
            : evolucaoGranularAsync;

    AsyncValue<List<Timeline360Event>> resolvedTimelineAsync =
        evolucaoAsync.hasValue
            ? AsyncData(evolucaoAsync.value!.timelinePreview)
            : timelineGranularAsync;

    final loadingPrimary = operacaoAsync.isLoading && !operacaoAsync.hasValue;
    final loadingFallback =
        resolvedAlunoAsync.isLoading && !resolvedAlunoAsync.hasValue;

    final proximaAcao360 = operacaoAsync.valueOrNull?.proximaAcao;
    final showOperacaoSticky =
        _tabController.index == 0 && resolvedAlunoAsync.hasValue;
    final showErrorChrome =
        !loadingPrimary &&
        !loadingFallback &&
        resolvedAlunoAsync.hasError &&
        !resolvedAlunoAsync.hasValue;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Ficha do aluno',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos');
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        safeArea: false,
        appBar:
            showErrorChrome
                ? FxShellAppBar(
                  title: 'Ficha do aluno',
                  subtitle: freshness,
                  onBack: () => safePopOrGo(context, '/alunos'),
                )
                : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            loadingPrimary || loadingFallback
                ? AlunoDetailLoadingSkeleton.forChrome(
                  tabController: _tabController,
                  chrome: chrome,
                  primary: primary,
                  listPreview: listPreview,
                )
                : resolvedAlunoAsync.when(
                  loading:
                      () => AlunoDetailLoadingSkeleton.forChrome(
                        tabController: _tabController,
                        chrome: chrome,
                        primary: primary,
                        listPreview: listPreview,
                      ),
                  error:
                      (e, _) => FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        message: friendlyError(
                          operacaoAsync.error ?? e,
                          fallback:
                              'Não foi possível carregar os dados do aluno.',
                        ),
                        onRetry: _reload360,
                        title: 'Não conseguimos carregar o aluno',
                      ),
                  data: (aluno) {
                    final perfilCompletion = copilotProfileCompletion(aluno);
                    final uiHints = operacaoAsync.valueOrNull?.operacaoUiHints;
                    final proximaForPriority = proximaAcao360;
                    final contactPriority = resolveOperacaoContactPriority(
                      aluno: aluno,
                      proximaAcao: proximaForPriority,
                      uiHints: uiHints,
                    );
                    final compactHero = contactPriority;
                    final topInset = MediaQuery.paddingOf(context).top;
                    final heroBodyHeight = Aluno360Layout.heroBodyHeight(
                      context,
                      compactContactPriority: compactHero,
                    );
                    final displayName = fxTitleCaseName(aluno.nome);

                    void openTabHelp() {
                      AnalyticsService.instance.track(
                        ProductEvents.aluno360HelpOpened,
                        props: {
                          'tab': switch (tabIndex) {
                            0 => 'operacao',
                            1 => 'evolucao',
                            _ => 'ferramentas',
                          },
                        },
                      );
                      switch (tabIndex) {
                        case 0:
                          showAluno360OperacaoHelpSheet(context);
                        case 1:
                          showAluno360EvolucaoHelpSheet(context);
                        default:
                          showAluno360FerramentasHelpSheet(context);
                      }
                    }

                    if (_fetchedAt == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _fetchedAt == null) _markFetched();
                      });
                    }
                    if (!_loggedFirstPaint) {
                      _loggedFirstPaint = true;
                      final totalMs =
                          DateTime.now().difference(_openedAt).inMilliseconds;
                      if (kDebugMode) {
                        debugPrint(
                          '[aluno360] first-paint total=${totalMs}ms '
                          'id=$alunoId (GET /360/operacao alone should dominate)',
                        );
                      }
                      // ignore: unawaited_futures
                      AnalyticsService.instance.track(
                        ProductEvents.aluno360FirstPaint,
                        props: {
                          'alunoId': alunoId,
                          'durationMs': totalMs,
                          'hadListPreview': listPreview != null,
                          'source': 'operacao',
                          'endpoint': '/360/operacao',
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _reload360,
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
                                            await _reload360();
                                          }
                                        },
                              ),
                              tabController: _tabController,
                              primary: primary,
                              mute: mute,
                              line: chrome.line,
                              displayName: displayName,
                              freshnessLabel: freshness,
                              ink: ink,
                              isDark: isDark,
                              onBack: () => safePopOrGo(context, '/alunos'),
                              onHelp: openTabHelp,
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
                                        operacaoAsync
                                            .valueOrNull
                                            ?.hasOpenCopilotTask ??
                                        false,
                                    aderenciaSemanal:
                                        operacaoAsync
                                            .valueOrNull
                                            ?.aderenciaSemanal
                                            .diasMaps,
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
                                    onLista: () =>
                                        safePopOrGo(context, '/alunos'),
                                    onEdit: () async {
                                      final updated = await context.push<bool>(
                                        '/alunos/$alunoId/editar',
                                        extra: aluno,
                                      );
                                      if (updated == true) {
                                        await _reload360();
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        chrome.sheetFill.withValues(alpha: 0),
                        chrome.sheetFill.withValues(alpha: 0.82),
                        chrome.sheetFill.withValues(alpha: 0.96),
                      ],
                      stops: const [0, 0.35, 1],
                    ),
                  ),
                  child: Aluno360OperacaoStickyCtaBar(
                    aluno: resolvedAlunoAsync.value!,
                    alunoId: alunoId,
                    proximaAcao360: proximaAcao360,
                    hasOpenCopilotTask360:
                        operacaoAsync.valueOrNull?.hasOpenCopilotTask ?? false,
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
