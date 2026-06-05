part of 'aluno_detail_screen.dart';

class _Aluno360Entrance extends StatelessWidget {
  const _Aluno360Entrance({
    required this.enabled,
    required this.delay,
    required this.child,
    this.onPlayed,
  });

  final bool enabled;
  final Duration delay;
  final Widget child;
  final VoidCallback? onPlayed;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) => onPlayed?.call());
    return ClipRect(
      child: FxPremiumEntrance(delay: delay, child: child),
    );
  }
}

class _AlunoDetailTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _AlunoDetailTabBarDelegate({
    required this.tabController,
    required this.primary,
    required this.mute,
    required this.line,
  });

  final TabController tabController;
  final Color primary;
  final Color mute;
  final Color line;

  @override
  double get minExtent => Aluno360Layout.tabBarHeight;

  @override
  double get maxExtent => Aluno360Layout.tabBarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final chrome = ShellChrome.of(context);
    return Material(
      color: chrome.sheetFill,
      elevation: overlapsContent ? 3 : 0,
      shadowColor: Colors.black.withValues(alpha: chrome.isDark ? 0.45 : 0.12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chrome.sheetFill,
          border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.65))),
        ),
        child: Semantics(
          container: true,
          label: 'Abas do perfil do aluno',
          child: TabBar(
            controller: tabController,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: mute,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Operação'),
              Tab(text: 'Evolução'),
              Tab(text: 'Ferramentas'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AlunoDetailTabBarDelegate oldDelegate) {
    return tabController != oldDelegate.tabController ||
        primary != oldDelegate.primary ||
        mute != oldDelegate.mute ||
        line != oldDelegate.line;
  }
}

class _AlunoDetailOperacaoTab extends ConsumerWidget {
  const _AlunoDetailOperacaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.aderenciaSemanal,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    required this.animateEntrance,
    required this.onEntrancePlayed,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeRisk =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final focusMode = ref.watch(alunoOperacaoFocusModeProvider(alunoId));

    Widget section(int step, Widget child) {
      return _Aluno360Entrance(
        enabled: animateEntrance,
        delay: operacaoSectionDelay(financeRisk: financeRisk, stepIndex: step),
        onPlayed: onEntrancePlayed,
        child: child,
      );
    }

    final operational = _AlunoOperationalStatusSection(
      aluno: aluno,
      alunoId: alunoId,
      isDark: isDark,
      primary: primary,
      aderenciaSemanal: aderenciaSemanal,
    );
    final copilot = _Aluno360CopilotCard(
      aluno: aluno,
      alunoId: alunoId,
      resumoAsync: autonomiaResumoAsync,
      proximaAcao360: proximaAcao360,
      hasOpenCopilotTask360: hasOpenCopilotTask360,
      isDark: isDark,
      showFocusToggle: true,
    );

    Widget diagnosticBody() {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: operational),
                const SizedBox(width: Aluno360Layout.sectionGap),
                Expanded(child: copilot),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              operational,
              const SizedBox(height: Aluno360Layout.sectionGap),
              copilot,
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (financeRisk) ...[
          section(
            0,
            _AlunoFinanceiroRiskBanner(alunoId: alunoId, isDark: isDark),
          ),
          const SizedBox(height: Aluno360Layout.sectionGap),
        ],
        section(1, _AlunoFollowUpCard(aluno: aluno, isDark: isDark)),
        const SizedBox(height: Aluno360Layout.sectionGap),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              focusMode
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section(3, copilot),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section(2, diagnosticBody()),
                      const SizedBox(height: Aluno360Layout.sectionGap),
                      section(
                        4,
                        _AlunoRecoveryInsightCard(
                          recoveryAsync: recoveryAsync,
                          isDark: isDark,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(height: Aluno360Layout.sectionGap),
                      section(
                        5,
                        _StudentQuickActions(
                          aluno: aluno,
                          isDark: isDark,
                          primary: primary,
                          onPassword: onPassword,
                          onEdit: onEdit,
                          onEvolve: onEvolve,
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _OperacaoFocusModeToggle extends ConsumerWidget {
  const _OperacaoFocusModeToggle({
    required this.alunoId,
    required this.primary,
    this.compact = false,
    this.iconOnly = false,
  });

  final int alunoId;
  final Color primary;
  final bool compact;
  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(alunoOperacaoFocusModeProvider(alunoId));
    final ink = fxScreenInk(context);

    if (iconOnly) {
      return Semantics(
        button: true,
        label:
            focusMode
                ? 'Desativar modo foco'
                : 'Ativar modo foco — mostra só follow-up e copiloto',
        child: IconButton.filledTonal(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .toggle(),
          icon: Icon(
            focusMode ? Icons.center_focus_strong : Icons.center_focus_weak,
            size: 18,
            color: focusMode ? primary : ink.withValues(alpha: 0.78),
          ),
          tooltip: focusMode ? 'Modo foco ativo' : 'Modo foco',
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (compact && !focusMode) {
      return Semantics(
        button: true,
        label: 'Ativar modo foco — mostra só follow-up e copiloto',
        child: TextButton(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .setFocus(true),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: ink.withValues(alpha: 0.78),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.center_focus_weak, size: 15, color: primary),
              const SizedBox(width: 4),
              const Text(
                'Modo foco',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        button: true,
        label:
            focusMode
                ? 'Desativar modo foco'
                : 'Ativar modo foco — mostra só follow-up e copiloto',
        child: OutlinedButton.icon(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .toggle(),
          icon: Icon(
            focusMode ? Icons.center_focus_strong : Icons.center_focus_weak,
            size: 16,
            color: focusMode ? primary : ink.withValues(alpha: 0.75),
          ),
          label: Text(
            focusMode ? 'Modo foco ativo' : 'Ver diagnóstico completo',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: focusMode ? primary : ink.withValues(alpha: 0.85),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            visualDensity: VisualDensity.compact,
            foregroundColor: focusMode ? primary : ink.withValues(alpha: 0.85),
            side: BorderSide(
              color: primary.withValues(alpha: focusMode ? 0.32 : 0.22),
            ),
            backgroundColor:
                focusMode ? primary.withValues(alpha: 0.08) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlunoDetailEvolucaoTab extends StatelessWidget {
  const _AlunoDetailEvolucaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
    required this.evolucaoAsync,
    required this.timeline360Async,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final AsyncValue<List<Timeline360Event>> timeline360Async;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvolucaoInteligenteCard(
          alunoId: alunoId,
          alunoNome: aluno.nome,
          evolucaoAsync: evolucaoAsync,
          isDark: isDark,
        ),
        const SizedBox(height: Aluno360Layout.sectionGap),
        _Aluno360Entrance(
          enabled: animateEntrance,
          delay: const Duration(milliseconds: 40),
          onPlayed: onEntrancePlayed,
          child: _Aluno360TimelineCard(
            aluno: aluno,
            timelineApiAsync: timeline360Async,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: Aluno360Layout.sectionGap),
        _Aluno360Entrance(
          enabled: animateEntrance,
          delay: const Duration(milliseconds: 80),
          onPlayed: onEntrancePlayed,
          child: _AlunoWeightActivityCard(
            aluno: aluno,
            alunoId: alunoId,
            isDark: isDark,
            ink: ink,
          ),
        ),
      ],
    );
  }
}

class _AlunoFinanceiroRiskBanner extends StatelessWidget {
  const _AlunoFinanceiroRiskBanner({
    required this.alunoId,
    required this.isDark,
  });

  final int alunoId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Semantics(
      button: true,
      label: 'Pendência financeira. Abrir mensalidades deste aluno',
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/financeiro?alunoId=$alunoId'),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: EagleTokens.bad, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendência financeira',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'Abrir mensalidades deste aluno',
                      style: TextStyle(color: mute, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: mute),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _OperacaoStickyCtaBar extends ConsumerWidget {
  const _OperacaoStickyCtaBar({
    required this.aluno,
    required this.alunoId,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.isDark,
  });

  final Aluno aluno;
  final int alunoId;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final line = ShellChrome.of(context).line;
    final creating = ref.watch(alunoCopilotCreatingProvider(alunoId));
    final openActions = ref.watch(alunoOpenIaActionsProvider(alunoId));
    final forceIa = ref.watch(alunoCopilotoForceIaProvider(alunoId));
    final iaAsync =
        forceIa ? ref.watch(alunoCopilotoActionProvider(alunoId)) : null;
    final hasOpenTask =
        findOpenCopilotTask(openActions.valueOrNull ?? const []) != null ||
        hasOpenCopilotTask360;
    final followUpDue = isAlunoFollowUpDue(aluno);
    final operacao = resolveAluno360OperacaoSnapshot(
      aluno: aluno,
      proximaAcao360: proximaAcao360,
      forceIa: forceIa,
      iaAsync: iaAsync,
      hasOpenTask: hasOpenTask,
      followUpDue: followUpDue,
    );
    final sticky = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;

    void openOutreach() {
      showAlunoOutreachMessageSheet(
        context,
        alunoId: alunoId,
        alunoNome: aluno.nome,
        message: operacao.outreachMessage,
        title: 'Mensagem sugerida',
        subtitle: 'Copiloto · revise antes de enviar.',
        icon: Icons.auto_awesome_rounded,
      );
    }

    void openChat({String? acao}) {
      final actionText = acao?.trim() ?? effectiveProxima?.acao.trim() ?? '';
      if (actionText.isNotEmpty && acaoSugereChat(actionText)) {
        openOutreach();
        return;
      }
      context.push('/alunos/$alunoId/chat', extra: aluno.nome);
    }

    void openCommandCenter() {
      context.push('/dashboard/command-center/copiloto');
    }

    void openEvolucao() {
      context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
    }

    void openEditAluno() {
      context.push('/alunos/$alunoId/editar', extra: aluno);
    }

    void onPrimary() {
      switch (sticky.destination) {
        case OperacaoStickyDestination.chat:
          openChat(acao: effectiveProxima?.acao);
        case OperacaoStickyDestination.commandCenter:
          openCommandCenter();
        case OperacaoStickyDestination.evolucao:
          openEvolucao();
        case OperacaoStickyDestination.editAluno:
          openEditAluno();
      }
    }
    final showSecondaryChat = shouldShowStickySecondaryChat(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
      followUpDue: followUpDue,
      proximaAcaoText: effectiveProxima?.acao,
    );
    final showSecondaryCommandCenter = shouldShowStickySecondaryCommandCenter(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
    );
    final hasSecondary =
        showSecondaryCommandCenter || showSecondaryChat;

    return SafeArea(
      top: false,
        child: Semantics(
        container: true,
        label: 'Ações rápidas da aba operação',
        child: Container(
        key: const ValueKey('aluno360_operacao_sticky_cta'),
        decoration: BoxDecoration(
          color: ShellChrome.of(context).sheetFill,
          border: Border(top: BorderSide(color: line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: hasSecondary ? 5 : 1,
              child: Semantics(
                button: true,
                label: operacao.stickyDisplayLabel,
                child: FxLiquidPrimaryButton(
                  icon: sticky.icon,
                  label: operacao.stickyDisplayLabel,
                  loading: creating,
                  loadingLabel: 'Criando…',
                  onPressed: creating ? null : onPrimary,
                ),
              ),
            ),
              if (showSecondaryCommandCenter) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _OperacaoStickySecondaryButton(
                    label: 'Tarefa',
                    icon: Icons.task_alt_rounded,
                    primary: primary,
                    semanticsLabel: 'Abrir tarefa no Command Center',
                    onPressed: openCommandCenter,
                  ),
                ),
              ],
              if (showSecondaryChat) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _OperacaoStickySecondaryButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    primary: primary,
                    semanticsLabel: 'Abrir chat com aluno',
                    onPressed:
                        () => openChat(acao: effectiveProxima?.acao),
                  ),
                ),
              ],
            ],
          ),
      ),
      ),
    );
  }
}

class _OperacaoStickySecondaryButton extends StatelessWidget {
  const _OperacaoStickySecondaryButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color primary;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: primary.withValues(alpha: 0.28)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoDetailFerramentasTab extends ConsumerWidget {
  const _AlunoDetailFerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.perfilCompletion,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final int perfilCompletion;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altura = formatAlturaDisplay(aluno.altura);
    final medidasAsync = ref.watch(alunoMedidasResumoProvider(alunoId));
    final medidas = medidasAsync.valueOrNull;
    final bf =
        medidas?.percGordura != null
            ? medidas!.percGordura!.toStringAsFixed(1)
            : null;
    final massaMagra =
        medidas?.massaMuscular != null
            ? medidas!.massaMuscular!.toStringAsFixed(1)
            : null;
    final evolucaoRoute = '/alunos/$alunoId/evolucao';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        medidasAsync.when(
          loading:
              () => FxLoading.sectionShimmer(context, height: 88, showHeader: false),
          error: (_, __) => const SizedBox.shrink(),
          data:
              (_) => LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 360 ? 2 : 4;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final aspectBase = crossAxisCount == 2 ? 1.45 : 1.1;
                  final childAspectRatio =
                      aspectBase / textScale.clamp(1.0, 2.2);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _MeasurementCard(
                        label: 'Idade',
                        value: (aluno.idade ?? '—').toString(),
                        unit: 'anos',
                        isDark: isDark,
                      ),
                      _MeasurementCard(
                        label: 'Altura',
                        value: altura.value,
                        unit: altura.unit,
                        isDark: isDark,
                      ),
                      _MeasurementCard(
                        label: 'BF',
                        value: bf ?? '—',
                        unit: '%',
                        isDark: isDark,
                        emptyHint: bf == null ? 'Registrar' : null,
                        onTap:
                            bf == null
                                ? () => context.push(evolucaoRoute, extra: aluno.nome)
                                : null,
                      ),
                      _MeasurementCard(
                        label: 'M. Magra',
                        value: massaMagra ?? '—',
                        unit: 'kg',
                        isDark: isDark,
                        emptyHint: massaMagra == null ? 'Registrar' : null,
                        onTap:
                            massaMagra == null
                                ? () => context.push(evolucaoRoute, extra: aluno.nome)
                                : null,
                      ),
                    ],
                  );
                },
              ),
        ),
        const SizedBox(height: 20),
        Text(
          'Módulos',
          style: AppTypography.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: BrandPalette.sectionHeading(primary, dark: isDark),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final aspectRatio = 2.55 / textScale.clamp(1.0, 2.2);
            return GridView.count(
          key: const ValueKey('aluno360_ferramentas_modulos'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _ModuleTile(
              icon: Icons.fitness_center,
              label: 'Treinos',
              sub:
                  aluno.diasSemTreino == null
                      ? 'Histórico'
                      : aluno.diasSemTreino! >= 7
                          ? '${aluno.diasSemTreino}d sem treino'
                          : 'Ativo recentemente',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/treinos-list',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.tune_rounded,
              label: 'Equipamentos',
              sub: aluno.equipamentosDisponiveis.isEmpty
                  ? 'Sem restrição'
                  : '${aluno.equipamentosDisponiveis.length} marcados',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/equipamentos'),
            ),
            _ModuleTile(
              icon: Icons.auto_awesome,
              label: 'IA Progresso',
              sub: 'Sugerir carga',
              badge: 'IA',
              highlight: true,
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/ia/progressao',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.show_chart,
              label: 'Medidas',
              sub:
                  bf != null || massaMagra != null
                      ? 'Última avaliação'
                      : 'Registrar medida',
              badge: bf == null && massaMagra == null ? 'Pendente' : null,
              isDark: isDark,
              onTap: () => context.push(evolucaoRoute, extra: aluno.nome),
            ),
            _ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Aderência',
              sub:
                  aluno.aderenciaPercent == null
                      ? 'Sem dados'
                      : '${aluno.aderenciaPercent}% semana',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/relatorio',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.flag_outlined,
              label: 'Sucesso',
              sub: 'Acompanhar',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/plano-sucesso',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.people,
              label: 'Anamnese',
              sub: perfilCompletion >= 85 ? 'Completa ✓' : 'Ver status',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/anamnese'),
            ),
            _ModuleTile(
              icon: Icons.attach_money,
              label: 'Mensalidades',
              sub: aluno.statusFinanceiro == 'INADIMPLENTE'
                  ? 'Em atraso'
                  : 'Em dia',
              badge: aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : null,
              isDark: isDark,
              onTap: () => context.push('/financeiro?alunoId=$alunoId'),
            ),
            _ModuleTile(
              icon: Icons.chat,
              label: 'Chat',
              sub: 'Última ação',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/chat',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.restaurant_menu,
              label: 'Dieta',
              sub: 'Plano atual',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/alimentar'),
            ),
            _ModuleTile(
              icon: Icons.video_camera_back,
              label: 'Feedback',
              sub: 'Análise de vídeo',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/feedback-video',
                extra: aluno.nome,
              ),
            ),
          ],
        );
          },
        ),
      ],
    );
  }
}
