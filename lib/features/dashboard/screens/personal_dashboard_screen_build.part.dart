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
                final alunosAtivos = snap.alunosAtivos;
                final riscoAlto = snap.riscoAlto;
                final alunosEmRisco = snap.alunosEmRisco;
                final checkinsHoje = snap.checkinsHoje;
                final checkinsTrend = snap.checkinsTrend;
                final receitaTrend = snap.receitaTrend;
                final agendaHoje = snap.agendaHoje;
                final riskDominante = snap.riskDominante;
                final dayFocus = snap.dayFocus;
                final focusRules = snap.focusRules;
                final dayFocusCoversRetention =
                    focusRules.dayFocusCoversRetention;
                final attentionRiskItems = snap.attentionRiskItems;
                final attentionVencItems = snap.attentionVencItems;
                final attentionVisible = snap.attentionVisible;
                final attentionCollapsedPreview =
                    snap.attentionCollapsedPreview;
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
                if (_focusPreferenceLoaded && _persistedFocusMode == null) {
                  final autoFocus = DashboardHomeFocusRules.defaultFocusMode(
                    dayFocus: dayFocus,
                    riskDominante: riskDominante,
                  );
                  if (_focusMode != autoFocus) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _focusMode = autoFocus);
                    });
                  }
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
                    ref.invalidate(alunosProvider);
                    ref.invalidate(historicoCheckinProvider);
                    ref.invalidate(aderenciaTop3Provider);
                    ref.invalidate(notificacoesProvider);
                    ref.invalidate(notificacoesNaoLidasProvider);
                    ref.invalidate(onboardingStatusProvider);
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
                      if (!focusRules.hidePromoBanners) ...[
                        const SliverToBoxAdapter(child: TrialCountdownBanner()),
                        const SliverToBoxAdapter(child: PlanUsageBanner()),
                        if (onboardingIncomplete)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                4,
                                TokensStrip.s4,
                                0,
                              ),
                              child: SetupOnboardingWidget(),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: DashboardActivationCta(
                              alunosAtivos: alunosAtivos,
                              temTreinos:
                                  primeiroTreinoCriado || checkinsHoje > 0,
                              temFinanceiro:
                                  _finData != null &&
                                  (_finData!.receitaMes > 0 ||
                                      _finData!.vencimentosProximos.isNotEmpty),
                            ),
                          ),
                      ],
                      SliverToBoxAdapter(
                        child: DashboardHomeHeader(
                          nomePersonal: data.nomePersonal,
                          logoUrl: data.logoUrl,
                          isDark: themeDark,
                          primary: primary,
                          focusMode: _focusMode,
                          onToggleFocus: _toggleFocusMode,
                          onProfileTap: () => context.push('/perfil'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: DashboardDayFocusBanner(
                          focus: dayFocus,
                          isDark: themeDark,
                          primary: primary,
                        ),
                      ),

                      // CENTRAL DE COMANDO — protagonista do dia
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: DashboardCommandCenterStickyHeaderDelegate(
                          isDark: themeDark,
                          primary: primary,
                          subtitle: commandCenterSubtitle,
                          compact: focusRules.compactCommandSticky,
                          showPrioritiesAction: showStickyPrioritiesAction,
                          trailingActionLabel: stickyCommandActionsLabel,
                          onTrailingAction:
                              stickyCommandActionsLabel != null
                                  ? openCommandQuickActions
                                  : null,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: dashboardEntryMotion(
                          context: context,
                          fade: _commandFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s4,
                              0,
                              TokensStrip.s4,
                              TokensStrip.s4,
                            ),
                            child: DashboardCommandCenterSection(
                              isDark: themeDark,
                              primary: primary,
                              finData: _finData,
                              nextActions: dashboardNextActions,
                              prioritiesSheetActions: prioritiesSheetActions,
                              showPrioritiesLink: showPrioritiesLink,
                              panelKey: _commandPanelKey,
                              mensagensNaoLidas: home.pulse?.mensagensNaoLidas,
                              hideHeader: true,
                              contextualSubtitle: commandCenterSubtitle,
                              collapseQuickLinks: focusRules.collapseQuickLinks,
                              alunosAtivos: alunosAtivos,
                              agendaHojeCount: agendaHoje,
                              unreadCount: snap.unreadCount,
                              copilotOpenCount:
                                  snap.filaAcoes
                                      .where((a) => a.tipo == 'IA_COPILOTO')
                                      .length,
                              isCommandPreparing: commandAsync.isLoading,
                              commandUnavailable: commandAsync.hasError,
                            ),
                          ),
                        ),
                      ),

                      if (riscoAlto > 0 &&
                          !attentionVisible &&
                          !focusRules.hideSecondaryRiskCtas)
                        SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/retencao'),
                              child: const Text('Ver saúde da base'),
                            ),
                          ),
                        ),

                      if (attentionVisible) ...[
                        SliverToBoxAdapter(
                          child: DashboardAttentionRail(
                            isDark: themeDark,
                            riskDominante: riskDominante,
                            riscoAlto: riscoAlto,
                            alunosAtivos: alunosAtivos,
                            dayFocusCoversRetention: dayFocusCoversRetention,
                            collapseAttention: focusRules.collapseAttention,
                            attentionRiskItems: attentionRiskItems,
                            attentionVencItems: attentionVencItems,
                            attentionCollapsedPreview:
                                attentionCollapsedPreview,
                            resetToken: _attentionSectionResetToken,
                            onReview: openAttentionReview,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: DashboardLayout.sliverSectionGap,
                          ),
                        ),
                      ],

                      // PULSO DO DIA — operação antes de receita
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            TokensStrip.s2,
                            TokensStrip.s4,
                            TokensStrip.s4,
                          ),
                          child: DashboardDayPulseStrip(
                            fade: _kpiFade,
                            isDark: themeDark,
                            alunosAtivos: alunosAtivos,
                            checkinsHoje: checkinsHoje,
                            checkinsTrend: checkinsTrend,
                            riscoAlto: riscoAlto,
                            agendaHoje: agendaHoje,
                            hideRiscoChip: alunosEmRisco.isNotEmpty,
                            primary: primary,
                            collapseBody: focusRules.collapsePulseBody,
                            onAtivos:
                                () => goPersonalShellTab(
                                  context,
                                  '/alunos?filtro=ativos',
                                ),
                            onCheckins: () => context.go('/checkin/historico'),
                            onAgenda:
                                () => goPersonalShellTab(context, '/agenda'),
                            onRisco:
                                riscoAlto > 0
                                    ? () => goPersonalShellTab(
                                      context,
                                      '/alunos?filtro=risco',
                                    )
                                    : () =>
                                        goPersonalShellTab(context, '/alunos'),
                            showEmptyTrendCta:
                                !checkinsTrend.any((v) => v > 0) &&
                                alunosAtivos > 0 &&
                                checkinsHoje == 0 &&
                                !focusRules.suppressSecondaryEmptyCtas &&
                                !focusRules.collapsePulseBody,
                            emptyTrendCtaLabel:
                                primeiroTreinoCriado
                                    ? 'Ver agenda'
                                    : 'Agendar primeiro treino',
                            onEmptyTrendCta:
                                () =>
                                    primeiroTreinoCriado
                                        ? goPersonalShellTab(context, '/agenda')
                                        : context.push('/treinos/novo'),
                          ),
                        ),
                      ),

                      if (!focusRules.omitSecondarySections) ...[
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: DashboardLayout.sliverSectionGap,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: DashboardCollapsibleSection(
                          title: DashboardMicrocopy.aderenciaDaSemana,
                          collapsedHint:
                              dayFocusCoversRetention
                                  ? 'Ranking semanal · expandir se precisar'
                                  : 'Treinos e ranking · ${DashboardMicrocopy.toqueParaExpandir}',
                          isDark: themeDark,
                          initiallyExpanded: !focusRules.collapseAderencia,
                          headerActionLabel:
                              focusRules.focusMode ? null : 'Relatório',
                          onHeaderAction:
                              focusRules.focusMode
                                  ? null
                                  : () => context.push('/relatorios/global'),
                          child: DashboardAderenciaSemanaWidget(
                            isDark: themeDark,
                            retentionFocus: dayFocusCoversRetention,
                            suppressEmptyActions:
                                focusRules.suppressSecondaryEmptyCtas,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(height: DashboardLayout.sliverTightGap),
                      ),
                      SliverToBoxAdapter(
                        child: DashboardCollapsibleSection(
                          title: DashboardMicrocopy.panoramaFinanceiro,
                          collapsedHint:
                              receitaAtual > 0
                                  ? 'R\$ ${receitaAtual.toInt()} recebido · ${DashboardMicrocopy.toqueParaExpandir}'
                                  : 'R\$ 0 recebido · meta do mês',
                          isDark: themeDark,
                          initiallyExpanded: !focusRules.collapseFinance,
                          child: dashboardEntryMotion(
                            context: context,
                            fade: _heroFade,
                            slideBegin: const Offset(0, 0.05),
                            child: DashboardFinancialHeroSection(
                              gradientCtrl: _gradientCtrl,
                              reduceMotion: reduceMotion,
                              themeDark: themeDark,
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
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(height: TokensStrip.s3),
                      ),
                      SliverToBoxAdapter(
                        child: DashboardCollapsibleToolsSection(
                          isDark: themeDark,
                          shortcutAspectRatio: shortcutAspectRatio,
                          hideFeaturedTools: focusRules.hideFeaturedTools,
                        ),
                      ),
                      ],

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
