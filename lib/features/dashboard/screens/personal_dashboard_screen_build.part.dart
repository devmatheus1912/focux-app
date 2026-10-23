part of 'personal_dashboard_screen.dart';

extension PersonalDashboardScreenBuild on _PersonalDashboardScreenState {
  Widget buildPersonalDashboardBody(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(dashboardHomeProvider);
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    final chromeOnDark = themeDark;

    return fxScreenA11yScope(
      label: FocuxMicrocopy.painelPersonal,
      child: FxContentWidthLimiter(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: homeAsync.when(
              skipLoadingOnReload: true,
              loading: () => DashboardShimmerLoading(themeDark: themeDark),
              error:
                  (e, _) => DashboardErrorState(
                    chromeOnDark: chromeOnDark,
                    primary: primary,
                    message: friendlyError(e),
                    onRetry: () {
                      ref.invalidate(dashboardHomeProvider);
                      _loadFinFromHome();
                    },
                  ),
              data: (home) {
                _applyHomeDeepLinkOnce(context);
                final data = home.personal;
                _maybeOfferTrial(data.totalAlunos);
                final coachPending = home.pulse?.coachPendentes ?? 0;

                if (_homeFetchedAt == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _homeFetchedAt != null) return;
                    setState(() => _homeFetchedAt = DateTime.now());
                  });
                }
                if (!_homeViewTracked) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _homeViewTracked) return;
                    _homeViewTracked = true;
                    AnalyticsService.instance.track(
                      ProductEvents.homeViewed,
                      props: {
                        'focus_mode': _focusMode,
                        'day_focus_kind': home.dayFocus?.kind?.name,
                        'risco_alto':
                            home.commandCenter.alunosEmRisco.length,
                        'score_count':
                            home.commandCenter.alunosScore.length,
                      },
                    );
                    if (!_homeTtvTracked) {
                      _homeTtvTracked = true;
                      AnalyticsService.instance.track(
                        ProductEvents.homeTtv,
                        props: {
                          'ms': DateTime.now()
                              .difference(_homeOpenedAt)
                              .inMilliseconds,
                          'day_focus_kind': home.dayFocus?.kind?.name,
                          'next_actions':
                              home.commandCenter.filaAcoes.length,
                        },
                      );
                    }
                  });
                }
                final planoFromHome = home.planoFeatures;
                if (planoFromHome != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref
                        .read(planoFeaturesProvider.notifier)
                        .seedFromHome(planoFromHome);
                  });
                }

                final snap = DashboardHomeSnapshot.build(
                  home: home,
                  finData: home.financeiro,
                  alunos: null,
                  commandCenter: home.commandCenter,
                  focusMode: _focusMode,
                  isCommandPreparing: false,
                );
                final mes = snap.mesLabel;
                final pendente = snap.pendente;
                final receitaAtual = snap.receitaAtual;
                final progressRaw = snap.progressRaw;
                final metaSuperada = snap.metaSuperada;
                final riskDominante = snap.riskDominante;
                final dayFocus = snap.dayFocus;
                final focusRules = snap.focusRules;
                final dashboardNextActions = snap.dashboardNextActions;
                final prioritiesSheetActions = snap.prioritiesSheetActions;
                final showPrioritiesLink = snap.showPrioritiesLink;

                if (_finData == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _finData != null) return;
                    _applyFinanceData(home.financeiro);
                  });
                }

                final onboardingFromHome = home.onboardingResumo;
                final landingCompleta =
                    planoFromHome?.landingCompleta ??
                    ref.watch(planoFeaturesProvider).value?.landingCompleta ??
                    false;
                final onboardingHidden = setupStepsHiddenFor(
                  (planoFromHome ?? ref.watch(planoFeaturesProvider).value)
                      ?.normalizeForTier(),
                );
                final onboardingIncomplete =
                    onboardingFromHome != null &&
                    !onboardingFromHome.ativacaoCompleta(
                      includeLinkBio: landingCompleta,
                      hiddenSteps: onboardingHidden,
                    );
                final primeiroTreinoCriado =
                    onboardingFromHome?.primeiroTreinoCriado ?? false;
                if (_focusPreferenceLoaded &&
                    !_autoFocusApplied &&
                    !_sessionFocusTouched) {
                  final autoFocus = DashboardHomeFocusRules.defaultFocusMode(
                    dayFocus: dayFocus,
                    riskDominante: riskDominante,
                    persisted: _persistedFocusMode,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted ||
                        _autoFocusApplied ||
                        _sessionFocusTouched) {
                      return;
                    }
                    setState(() {
                      _autoFocusApplied = true;
                      _focusMode = autoFocus;
                    });
                  });
                }
                const commandCenterSubtitle =
                    DashboardMicrocopy.commandCenterSubtitle;
                final hojeCard = hojePersonalCard(
                  acoes: dashboardNextActions,
                  temAluno: data.totalAlunos > 0,
                  proximoPasso:
                      onboardingFromHome == null
                          ? null
                          : nextSetupStep(
                            onboardingFromHome,
                            landingCompleta: landingCompleta,
                            hidden: onboardingHidden,
                          ),
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    DashboardHomeClientCache.clear();
                    PlanoFeaturesBffCache.clear();
                    ref.invalidate(dashboardHomeProvider);
                    ref.invalidate(notificacoesProvider);
                    ref.invalidate(notificacoesNaoLidasProvider);
                    await _loadFinFromHome();
                    if (mounted) {
                      setState(() => _homeFetchedAt = DateTime.now());
                    }
                    AnalyticsService.instance.track(ProductEvents.homeRefreshed);
                    if (context.mounted) {
                      FeedbackHelper.showSuccess(
                        context,
                        DashboardMicrocopy.painelAtualizado,
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: _homeScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          ...buildDashboardHomePrimarySlivers(
                            card: hojeCard,
                            onCard: () {
                              final item = hojeCard.acao;
                              if (item != null) {
                                openDashboardCommandAction(
                                  context: context,
                                  ref: ref,
                                  item: item,
                                  source: 'hoje_card',
                                );
                                return;
                              }
                              final rota = hojeCard.rota;
                              if (rota != null) context.push(rota);
                            },
                            painelExtra: [
                              DashboardFinancialHeroSection(
                                mes: mes,
                                receitaAtual: receitaAtual,
                                pendente: pendente,
                                progressRaw: progressRaw,
                                metaSuperada: metaSuperada,
                                loadingFin: false,
                                finData: home.financeiro,
                              ),
                              DashboardHomeToolsSection(
                                isDark: themeDark,
                                homePlanoFeatures: home.planoFeatures,
                                onboardingCompleto:
                                    onboardingFromHome?.ativacaoCompleta(
                                      includeLinkBio: landingCompleta,
                                      hiddenSteps: onboardingHidden,
                                    ) ??
                                    false,
                              ),
                            ],
                            context: context,
                            snap: snap,
                            focusRules: focusRules,
                            dayFocus: dayFocus,
                            isDark: themeDark,
                            primary: primary,
                            nomePersonal: data.nomePersonal,
                            logoUrl: data.logoUrl,
                            focusMode: _focusMode,
                            onToggleFocus: _toggleFocusMode,
                            commandCenterSubtitle: commandCenterSubtitle,
                            finData: home.financeiro,
                            nextActions: dashboardNextActions,
                            prioritiesSheetActions: prioritiesSheetActions,
                            showPrioritiesLink: showPrioritiesLink,
                            commandPanelKey: _commandPanelKey,
                            mensagensNaoLidas: home.pulse?.mensagensNaoLidas,
                            commandFade: _commandFade,
                            kpiFade: _kpiFade,
                            isCommandPreparing: false,
                            commandUnavailable: false,
                            onboardingIncomplete: onboardingIncomplete,
                            primeiroTreinoCriado: primeiroTreinoCriado,
                            onboardingFromHome: onboardingFromHome,
                            prioritiesChipVisible: false,
                            pulseEmptyHint: home.pulse?.emptyHint,
                            notificacoesNaoLidasOverride:
                                home.notificacoesNaoLidas,
                            brandAccent: dashboardParseBrandColor(
                              data.corPrimaria,
                            ),
                            agendaItems: home.commandCenter.agendaHoje,
                            alunosScore: home.commandCenter.alunosScore,
                            freshnessLabel:
                                _homeFetchedAt == null
                                    ? DashboardHomeClientCache.fetchedAt == null
                                        ? null
                                        : DashboardMicrocopy.atualizadoHa(
                                          DateTime.now().difference(
                                            DashboardHomeClientCache.fetchedAt!,
                                          ),
                                        )
                                    : DashboardMicrocopy.atualizadoHa(
                                      DateTime.now().difference(
                                        _homeFetchedAt!,
                                      ),
                                    ),
                            showCoachBanner:
                                _coachLoaded && !_coachSeen,
                            onDismissCoach: _dismissCoach,
                            coachPending: coachPending,
                            coachPendingLabel:
                                coachPendingChipLabel(coachPending),
                            onQuickSearch:
                                () => showDashboardQuickSearchSheet(
                                  context,
                                  isDark: themeDark,
                                  primary: primary,
                                ),
                            onHelp: () => showDashboardHomeHelpSheet(context),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom +
                                  DashboardLayout.bottomDockClearance,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
