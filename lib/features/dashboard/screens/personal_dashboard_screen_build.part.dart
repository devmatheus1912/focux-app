part of 'personal_dashboard_screen.dart';

extension PersonalDashboardScreenBuild on _PersonalDashboardScreenState {
  Widget buildPersonalDashboardBody(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final homeAsync = ref.watch(dashboardHomeProvider);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
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
                final data = home.personal;
                final screenWidth = MediaQuery.sizeOf(context).width;
                final isCompactPhone = DashboardLayout.isCompact(screenWidth);
                final shortcutAspectRatio = isCompactPhone ? 2.55 : 2.85;

                final snap = DashboardHomeSnapshot.build(
                  home: home,
                  finData: home.financeiro,
                  alunos: null,
                  historicoCheckins: null,
                  commandCenter: home.commandCenter,
                  inboxUnread: 0,
                  inboxReady: false,
                  focusMode: _focusMode,
                  isCommandPreparing: false,
                );
                final mes = snap.mesLabel;
                final pendente = snap.pendente;
                final receitaAtual = snap.receitaAtual;
                final progressRaw = snap.progressRaw;
                final metaSuperada = snap.metaSuperada;
                final receitaTrend = snap.receitaTrend;
                final riskDominante = snap.riskDominante;
                final dayFocus = snap.dayFocus;
                final focusRules = snap.focusRules;
                final attentionRiskItems = snap.attentionRiskItems;
                final attentionVencItems = snap.attentionVencItems;
                final dashboardNextActions = snap.dashboardNextActions;
                final prioritiesSheetActions = snap.prioritiesSheetActions;
                final showPrioritiesLink = snap.showPrioritiesLink;

                if (_finData == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _finData != null) return;
                    _applyFinanceData(home.financeiro);
                  });
                }

                final onboardingAsync = ref.watch(onboardingStatusProvider);
                final onboardingIncomplete = onboardingAsync.maybeWhen(
                  data: (s) => !s.ativacaoCompleta,
                  orElse: () => false,
                );
                final primeiroTreinoCriado = onboardingAsync.maybeWhen(
                  data: (s) => s.primeiroTreinoCriado,
                  orElse: () => false,
                );
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

                void openAttentionReview() {
                  if (attentionRiskItems.isNotEmpty) {
                    context.push('/alunos/${attentionRiskItems.first.id}');
                    return;
                  }
                  if (attentionVencItems.isNotEmpty) {
                    context.go('/financeiro');
                    return;
                  }
                  goPersonalShellTab(context, '/alunos?filtro=risco');
                }

                // Sticky só depois do painel de próximas ações sair da tela
                // (medido via GlobalKey) — um único CTA no viewport.
                final showStickyPrioritiesAction =
                    dashboardShowsStickyPrioritiesAction(
                      panelOffscreen: _prioritiesPanelOffscreen,
                      showPrioritiesLink: showPrioritiesLink,
                    );
                final stickyCommandActionsLabel =
                    showStickyPrioritiesAction
                        ? DashboardMicrocopy.verPrioridades
                        : null;

                void openCommandQuickActions() {
                  if (!showPrioritiesLink) return;
                  showCommandActionsSheet(
                    context,
                    isDark: themeDark,
                    primary: primary,
                    actions: prioritiesSheetActions,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardHomeProvider);
                    ref.invalidate(notificacoesProvider);
                    ref.invalidate(notificacoesNaoLidasProvider);
                    await _loadFinFromHome();
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
                            attentionSectionResetToken:
                                _attentionSectionResetToken,
                            onReviewAttention: openAttentionReview,
                            onboardingIncomplete: onboardingIncomplete,
                            primeiroTreinoCriado: primeiroTreinoCriado,
                            prioritiesChipVisible: showStickyPrioritiesAction,
                          ),
                          if (!focusRules.omitSecondarySections)
                            SliverToBoxAdapter(
                              child: DashboardHomeSecondaryBlock(
                                focusRules: focusRules,
                                isDark: themeDark,
                                heroPrimary: heroPrimary,
                                heroDeep: heroDeep,
                                mes: mes,
                                receitaAtual: receitaAtual,
                                pendente: pendente,
                                progressRaw: progressRaw,
                                metaSuperada: metaSuperada,
                                loadingFin: false,
                                counterAnim: _counterAnim,
                                finData: home.financeiro,
                                receitaTrend: receitaTrend,
                                gradientCtrl: _gradientCtrl,
                                reduceMotion: reduceMotion,
                                heroFade: _heroFade,
                                shortcutAspectRatio: shortcutAspectRatio,
                                topAderencia: home.topAderencia,
                                onOpenRelatorio:
                                    () =>
                                        context.push('/relatorios/global'),
                              ),
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
                      if (showStickyPrioritiesAction)
                        DashboardPrioritiesOverlay(
                          isDark: themeDark,
                          primary: primary,
                          label:
                              stickyCommandActionsLabel ??
                              DashboardMicrocopy.verPrioridades,
                          onTap: openCommandQuickActions,
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
