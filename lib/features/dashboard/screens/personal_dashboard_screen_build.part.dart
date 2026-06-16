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
            final isCompactPhone = screenWidth < 390;
            final shortcutAspectRatio = isCompactPhone ? 2.75 : 3.05;

            // Computed values for hero card
            final monthNames = [
              'janeiro',
              'fevereiro',
              'março',
              'abril',
              'maio',
              'junho',
              'julho',
              'agosto',
              'setembro',
              'outubro',
              'novembro',
              'dezembro',
            ];
            final mes = monthNames[DateTime.now().month - 1];
            final pendente = ((_finData?.previsaoReceita ?? 0) -
                    (_finData?.receitaMes ?? 0))
                .clamp(0.0, double.infinity);
            final metaReceita = _finData?.previsaoReceita ?? 0;
            final receitaAtual = _finData?.receitaMes ?? 0;
            final progressRaw =
                metaReceita > 0 ? receitaAtual / metaReceita : 0.0;
            final metaSuperada = metaReceita > 0 && receitaAtual >= metaReceita;

            final alunosAtivos = alunosAsync.maybeWhen(
              data: (alunos) => alunos.where((a) => a.status == 'ATIVO').length,
              orElse: () => data.alunosAtivos,
            );
            final riscoAlto = alunosAsync.maybeWhen(
              data: (alunos) => alunos.where((a) => a.emRisco).length,
              orElse: () => 0,
            );
            final alunosEmRisco = alunosAsync.maybeWhen(
              data: (alunos) => alunos.where((a) => a.emRisco).toList(),
              orElse: () => const <Aluno>[],
            );

            final hoje = DateTime.now();
            final checkinsHoje = historicoCheckinsAsync.maybeWhen(
              data: (items) {
                bool sameDay(DateTime a, DateTime b) =>
                    a.year == b.year && a.month == b.month && a.day == b.day;
                return items.where((e) {
                  final concluded = DateTime.tryParse(e.concluidoEm ?? '');
                  if (concluded == null) return false;
                  return sameDay(concluded.toLocal(), hoje);
                }).length;
              },
              orElse: () => 0,
            );
            final checkinsTrend = historicoCheckinsAsync.maybeWhen(
              data: (items) => dashboardCheckinsSparklineUltimos7Dias(items),
              orElse: () => List<double>.filled(7, 0),
            );
            final receitaTrend = dashboardReceitaSparklineMensal(
              _finData?.evolucaoMensal ?? const [],
            );
            final agendaHoje = commandAsync.maybeWhen(
              data: (cc) => cc.agendaHoje.length,
              orElse: () => 0,
            );
            final attentionVisible =
                alunosEmRisco.isNotEmpty ||
                (_finData != null && _finData!.vencimentosProximos.isNotEmpty);
            final onboardingAsync = ref.watch(onboardingStatusProvider);
            final onboardingIncomplete = onboardingAsync.maybeWhen(
              data: (s) => !s.ativacaoCompleta,
              orElse: () => false,
            );
            final primeiroTreinoCriado = onboardingAsync.maybeWhen(
              data: (s) => s.primeiroTreinoCriado,
              orElse: () => false,
            );
            final riskDominante =
                alunosAtivos > 0 &&
                riscoAlto >= math.max(2, (alunosAtivos * 0.5).ceil());
            final vencimentosCount = _finData?.vencimentosProximos.length ?? 0;
            final dayFocus = DashboardDayFocus.resolve(
              riscoAlto: riscoAlto,
              alunosAtivos: alunosAtivos,
              checkinsHoje: checkinsHoje,
              agendaHoje: agendaHoje,
              receitaMes: receitaAtual,
              vencimentosPendentes: vencimentosCount,
              riskDominante: riskDominante,
            );
            final dayFocusCoversRetention =
                dayFocus.headline == 'Cobrança e retenção hoje' ||
                dayFocus.headline == 'Retomada urgente da base';

            final attentionRiskItems =
                alunosEmRisco.take(riskDominante ? 2 : 4).toList();
            final attentionVencItems =
                (_finData?.vencimentosProximos ?? const []).take(2).toList();
            final attentionItemCount =
                attentionRiskItems.length + attentionVencItems.length;
            const commandCenterSubtitle =
                'Próximas ações com maior impacto hoje.';

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

            final filaAcoes = commandAsync.maybeWhen(
              data: (cc) => cc.filaAcoes,
              orElse: () => const <FilaAcaoResumo>[],
            );
            final chatAsync = ref.watch(chatInboxProvider);
            final unreadCount = chatAsync.maybeWhen(
              data:
                  (items) =>
                      items.fold<int>(0, (sum, item) => sum + item.naoLidas),
              orElse: () => 0,
            );
            final alunosRiscoCount = commandAsync.maybeWhen(
              data: (cc) => cc.alunosEmRisco.length,
              orElse: () => 0,
            );
            final cobrancasPendentes = commandAsync.maybeWhen(
              data: (cc) => cc.cobrancasPendentes.length,
              orElse: () => _finData?.totalInadimplentes ?? 0,
            );
            final dashboardNextActions = buildDashboardNextActions(
              filaAcoes: filaAcoes,
              unreadCount: unreadCount,
              alunosRisco: alunosRiscoCount,
              cobrancasPendentes: cobrancasPendentes,
              agendaHoje: agendaHoje,
              hideRiskSummary: alunosEmRisco.isNotEmpty,
              isCommandPreparing: commandAsync.isLoading,
            );
            final showStickyPrioritiesAction =
                dashboardNextActions.length > 1 && _homeScrollOffset >= 80;
            final stickyCommandActionsLabel =
                dashboardNextActions.length > 1
                    ? DashboardMicrocopy.verPrioridades
                    : null;

            void openCommandQuickActions() {
              if (dashboardNextActions.length < 2) return;
              showCommandActionsSheet(
                context,
                isDark: themeDark,
                primary: primary,
                actions: buildDashboardSheetActions(
                  curated: dashboardNextActions,
                  filaAcoes: filaAcoes,
                ),
              );
            }

            final String? attentionCollapsedPreview;
            if (attentionRiskItems.isNotEmpty) {
              final first = attentionRiskItems.first;
              attentionCollapsedPreview =
                  '${first.nome} · ${attentionSignalLabel(first)}';
            } else if (attentionVencItems.isNotEmpty) {
              final first = attentionVencItems.first;
              attentionCollapsedPreview =
                  '${first.alunoNome} · R\$ ${first.valor.toStringAsFixed(0)} pendente';
            } else {
              attentionCollapsedPreview = null;
            }

            final link = BrandPalette.sectionLink(primary, dark: themeDark);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                RefreshIndicator(
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
                      const SliverToBoxAdapter(child: TrialCountdownBanner()),
                      const SliverToBoxAdapter(child: PlanUsageBanner()),
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
                      ),
                      if (!onboardingIncomplete)
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            4,
                            TokensStrip.s4,
                            TokensStrip.s3,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dashboardGreeting(data.nomePersonal),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.35,
                                        height: 1.15,
                                        color:
                                            themeDark
                                                ? EagleTokens.darkInk
                                                : TokensStrip.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: DashboardLayout.headerIconGap),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const ShellThemeToggle(size: 36),
                                  SizedBox(width: DashboardLayout.headerIconGap),
                                  const NotificacaoBadgeButton(size: 36),
                                  SizedBox(width: DashboardLayout.headerIconGap),
                                  DashboardHeaderProfileAvatar(
                                    primary: primary,
                                    isDark: themeDark,
                                    photoUrl: data.logoUrl,
                                    initials: fxInitials(
                                      data.nomePersonal ?? 'F',
                                    ),
                                    onTap: () => context.push('/perfil'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                              hideRiskSummary: alunosEmRisco.isNotEmpty,
                              hideHeader: true,
                              contextualSubtitle: commandCenterSubtitle,
                            ),
                          ),
                        ),
                      ),

                      if (riscoAlto > 0 && !attentionVisible)
                        SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/retencao'),
                              child: const Text('Ver saúde da base'),
                            ),
                          ),
                        ),

                      // PRECISA DE ATENÇÃO — colapsável quando muitos sinais
                      if (attentionVisible) ...[
                        SliverToBoxAdapter(
                          child: DashboardCollapsibleSection(
                            title: 'Precisa de atenção',
                            collapsedHint:
                                riskDominante
                                    ? '$riscoAlto de $alunosAtivos · toque em Revisar'
                                    : riscoAlto > 0
                                    ? '$riscoAlto no radar · toque em Revisar'
                                    : 'Cobranças pendentes · toque em Revisar',
                            collapsedActionLabel: 'Revisar',
                            onCollapsedAction: openAttentionReview,
                            collapsedPreview: attentionCollapsedPreview,
                            isDark: themeDark,
                            initiallyExpanded:
                                !dayFocusCoversRetention && riscoAlto <= 3,
                            resetToken: _attentionSectionResetToken,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push('/retencao'),
                                    child: const Text('Saúde da base'),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        () =>
                                            goPersonalShellTab(
                                              context,
                                              '/alunos?filtro=risco',
                                            ),
                                    child: Text(
                                      riscoAlto > 1
                                          ? 'Ver tudo · +${riscoAlto - 1}'
                                          : 'Ver tudo',
                                    ),
                                  ),
                                ),
                                Semantics(
                                  container: true,
                                  explicitChildNodes: true,
                                  label: dashboardAttentionCarouselSemantics(
                                    attentionItemCount,
                                  ),
                                  child: DashboardHorizontalScrollPeek(
                                    showPeek: attentionItemCount > 1,
                                    child: SizedBox(
                                      height: 184,
                                      child: ListView.separated(
                                        // ignore: deprecated_member_use
                                        cacheExtent: 280,
                                        key: const PageStorageKey(
                                          'personal-attention-rail',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: TokensStrip.s4,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: attentionItemCount,
                                        separatorBuilder:
                                            (_, __) =>
                                                SizedBox(width: TokensStrip.s3),
                                        itemBuilder: (context, index) {
                                          if (index <
                                              attentionRiskItems.length) {
                                            final aluno =
                                                attentionRiskItems[index];
                                            return RepaintBoundary(
                                              child: DashboardAttentionCard(
                                                listIndex: index + 1,
                                                listTotal: attentionItemCount,
                                                nome: aluno.nome,
                                                objetivo: aluno.objetivo,
                                                titulo: attentionSignalLabel(
                                                  aluno,
                                                ),
                                                subt: attentionSignalSub(aluno),
                                                acao: 'Revisar',
                                                isDark: themeDark,
                                                showStatusBadge:
                                                    !riskDominante ||
                                                    aluno.inadimplente ||
                                                    aluno.statusFinanceiro ==
                                                        'INADIMPLENTE',
                                                statusAccent: EagleTokens.warn,
                                                onTap:
                                                    () => context.push(
                                                      '/alunos/${aluno.id}',
                                                    ),
                                              ),
                                            );
                                          }
                                          final v =
                                              attentionVencItems[index -
                                                  attentionRiskItems.length];
                                          return RepaintBoundary(
                                            child: DashboardAttentionCard(
                                              listIndex: index + 1,
                                              listTotal: attentionItemCount,
                                              nome: v.alunoNome,
                                              titulo: 'Inadimplente',
                                              subt:
                                                  'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                                              acao: 'Cobrar',
                                              isDark: themeDark,
                                              onTap:
                                                  () =>
                                                      context.go('/financeiro'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: DashboardLayout.sliverSectionGap),
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
                                    : () => goPersonalShellTab(context, '/alunos'),
                            showEmptyTrendCta:
                                !checkinsTrend.any((v) => v > 0) &&
                                alunosAtivos > 0 &&
                                !dayFocusCoversRetention &&
                                !primeiroTreinoCriado &&
                                checkinsHoje == 0,
                            emptyTrendCtaLabel: 'Agendar primeiro treino',
                            onEmptyTrendCta:
                                () => context.push('/treinos/novo'),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(height: DashboardLayout.sliverSectionGap),
                      ),
                      SliverToBoxAdapter(
                        child: DashboardCollapsibleSection(
                          title: 'Aderência da semana',
                          collapsedHint:
                              'Treinos parados e ranking · toque para expandir',
                          isDark: themeDark,
                          headerActionLabel: 'Relatório',
                          onHeaderAction:
                              () => context.push('/relatorios/global'),
                          child: DashboardAderenciaSemanaWidget(
                            isDark: themeDark,
                            retentionFocus: dayFocusCoversRetention,
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
                                  ? 'R\$ ${receitaAtual.toInt()} recebido · toque para expandir'
                                  : 'R\$ 0 recebido · meta do mês · toque para expandir',
                          isDark: themeDark,
                          initiallyExpanded:
                              !dayFocusCoversRetention && receitaAtual > 0,
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
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 88,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStickyPrioritiesAction &&
                    stickyCommandActionsLabel != null &&
                    dashboardShowsFloatingPrioritiesChip(_homeScrollOffset))
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 4,
                    right: TokensStrip.s4,
                    child: Semantics(
                      button: true,
                      label: stickyCommandActionsLabel,
                      child: Material(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(
                          alpha: themeDark ? 0.35 : 0.12,
                        ),
                        color:
                            themeDark
                                ? EagleTokens.darkCard
                                : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: openCommandQuickActions,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              stickyCommandActionsLabel,
                              style: dashboardChipLabelStyle(link),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
            ),
          ),
        ),
      ),
    );
  }
}
