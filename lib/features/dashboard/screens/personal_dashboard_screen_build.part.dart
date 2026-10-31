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
                      invalidatePersonalDashboardHome(ref);
                    },
                  ),
              data: (home) {
                _applyHomeDeepLinkOnce(context);
                final data = home.personal;
                _maybeOfferTrial(data.totalAlunos);

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
                  focusMode: false,
                  isCommandPreparing: false,
                );

                final onboardingFromHome = home.onboardingResumo;
                final onboardingIncomplete =
                    onboardingFromHome != null &&
                    !onboardingFromHome.ativacaoCompleta();
                final primeiroTreinoCriado =
                    onboardingFromHome?.primeiroTreinoCriado ?? false;
                return RefreshIndicator(
                  onRefresh: () async {
                    DashboardHomeClientCache.clear();
                    PlanoFeaturesBffCache.clear();
                    invalidatePersonalDashboardHome(ref);
                    ref.invalidate(notificacoesProvider);
                    ref.invalidate(notificacoesNaoLidasProvider);
                    try {
                      await ref.read(dashboardHomeProvider.future);
                    } catch (_) {
                      // O erro aparece no próprio estado da tela.
                    }
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          ...buildDashboardHomePrimarySlivers(
                            context: context,
                            snap: snap,
                            isDark: themeDark,
                            primary: primary,
                            nomePersonal: data.nomePersonal,
                            logoUrl: data.logoUrl,
                            commandCenter: home.commandCenter,
                            finData: home.financeiro,
                            temAluno: data.totalAlunos > 0,
                            onboardingIncomplete: onboardingIncomplete,
                            primeiroTreinoCriado: primeiroTreinoCriado,
                            onboardingFromHome: onboardingFromHome,
                            proximoPasso:
                                onboardingFromHome == null
                                    ? null
                                    : nextSetupStep(onboardingFromHome),
                            notificacoesNaoLidasOverride:
                                home.notificacoesNaoLidas,
                            brandAccent: dashboardParseBrandColor(
                              data.corPrimaria,
                            ),
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
