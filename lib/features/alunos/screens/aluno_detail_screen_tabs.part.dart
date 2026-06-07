part of 'aluno_detail_screen.dart';

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
    final operacaoSnapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final contactPriority = operacaoSnapshot?.contactPriority ?? false;
    final showRecovery = alunoTemHistoricoWearable(recoveryAsync.valueOrNull);

    return Aluno360OperacaoTab(
      alunoId: alunoId,
      showFinanceRisk: financeRisk,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      financeRiskBanner:
          financeRisk
              ? _AlunoFinanceiroRiskBanner(alunoId: alunoId, isDark: isDark)
              : null,
      followUpCard: _AlunoFollowUpCard(
        aluno: aluno,
        isDark: isDark,
        compactContactPriority: shouldCompactFollowUpForContactPriority(
          contactPriority: contactPriority,
        ),
      ),
      operationalSection: Aluno360OperationalStatusSection(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        primary: primary,
        aderenciaSemanal: aderenciaSemanal,
      ),
      copilotCard: Aluno360CopilotCard(
        aluno: aluno,
        alunoId: alunoId,
        resumoAsync: autonomiaResumoAsync,
        proximaAcao360: proximaAcao360,
        hasOpenCopilotTask360: hasOpenCopilotTask360,
        isDark: isDark,
        showFocusToggle: true,
        focusMode: ref.watch(alunoOperacaoFocusModeProvider(alunoId)),
      ),
      recoveryCard:
          showRecovery
              ? _AlunoRecoveryInsightCard(
                recoveryAsync: recoveryAsync,
                isDark: isDark,
                primary: primary,
              )
              : null,
      quickActions: _StudentQuickActions(
        aluno: aluno,
        isDark: isDark,
        primary: primary,
        onPassword: onPassword,
        onEdit: onEdit,
        onEvolve: onEvolve,
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
        Aluno360OperacaoEntrance(
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
        Aluno360OperacaoEntrance(
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
    final operacao =
        ref.watch(aluno360OperacaoProvider(alunoId)) ??
        resolveAluno360OperacaoSnapshot(
          aluno: aluno,
          proximaAcao360: proximaAcao360,
          forceIa: forceIa,
          iaAsync: iaAsync,
          hasOpenTask:
              findOpenCopilotTask(openActions.valueOrNull ?? const []) != null ||
              hasOpenCopilotTask360,
          followUpDue: isAlunoFollowUpDue(aluno),
          wearableRelevant: alunoTemHistoricoWearable(
            ref.watch(alunoRecoveryProvider(alunoId)).valueOrNull,
          ),
        );
    final sticky = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hasOpenTask =
        findOpenCopilotTask(openActions.valueOrNull ?? const []) != null ||
        hasOpenCopilotTask360;
    final followUpDue = isAlunoFollowUpDue(aluno);

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
      if (sticky.isChatAction ||
          (actionText.isNotEmpty && acaoSugereChat(actionText))) {
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
