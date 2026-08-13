part of 'personal_dashboard_screen.dart';

extension PersonalDashboardScreenBuild on _PersonalDashboardScreenState {
  Widget buildPersonalDashboardBody(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final homeAsync = ref.watch(dashboardHomeProvider);
    final commandAsync = ref.watch(commandCenterProvider);
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final themeDark = Theme.of(context).brightness == Brightness.dark;
    final alunosAsync = ref.watch(alunosProvider);
    final historicoCheckinsAsync = ref.watch(historicoCheckinProvider);
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
                      ref.invalidate(alunosProvider);
                      _loadFinFromHome();
                    },
                  ),
              data: (home) {
                final data = home.personal;
                final screenWidth = MediaQuery.sizeOf(context).width;
                final isCompactPhone = DashboardLayout.isCompact(screenWidth);
                final shortcutAspectRatio = isCompactPhone ? 2.75 : 3.05;

                final chatAsync = ref.watch(chatInboxProvider);
                final unreadFromInbox = chatAsync.maybeWhen(
                  data:
                      (items) => items.fold<int>(
                        0,
                        (sum, item) => sum + item.naoLidas,
                      ),
                  orElse: () => 0,
                );
                final snap = DashboardHomeSnapshot.build(
                  home: home,
                  finData: _finData,
                  alunos: alunosAsync.asData?.value,
                  historicoCheckins: historicoCheckinsAsync.asData?.value,
                  commandCenter: commandAsync.asData?.value,
                  inboxUnread: unreadFromInbox,
                  inboxReady: chatAsync.hasValue,
                  focusMode: _focusMode,
                  isCommandPreparing: commandAsync.isLoading,
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
                    _persistedFocusMode == null) {
                  final autoFocus = DashboardHomeFocusRules.defaultFocusMode(
                    dayFocus: dayFocus,
                    riskDominante: riskDominante,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted ||
                        _autoFocusApplied ||
                        _persistedFocusMode != null) {
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
                  child: CustomScrollView(
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
                        showStickyPrioritiesAction: showStickyPrioritiesAction,
                        stickyCommandActionsLabel: stickyCommandActionsLabel,
                        onTrailingAction:
                            stickyCommandActionsLabel != null
                                ? openCommandQuickActions
                                : null,
                        finData: _finData,
                        nextActions: dashboardNextActions,
                        prioritiesSheetActions: prioritiesSheetActions,
                        showPrioritiesLink: showPrioritiesLink,
                        commandPanelKey: _commandPanelKey,
                        mensagensNaoLidas: home.pulse?.mensagensNaoLidas,
                        commandFade: _commandFade,
                        kpiFade: _kpiFade,
                        isCommandPreparing: commandAsync.isLoading,
                        commandUnavailable: commandAsync.hasError,
                        attentionSectionResetToken: _attentionSectionResetToken,
                        onReviewAttention: openAttentionReview,
                        onboardingIncomplete: onboardingIncomplete,
                        primeiroTreinoCriado: primeiroTreinoCriado,
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
                            loadingFin: _loadingFin,
                            counterAnim: _counterAnim,
                            finData: _finData,
                            receitaTrend: receitaTrend,
                            gradientCtrl: _gradientCtrl,
                            reduceMotion: reduceMotion,
                            heroFade: _heroFade,
                            shortcutAspectRatio: shortcutAspectRatio,
                            onOpenRelatorio:
                                () => context.push('/relatorios/global'),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
