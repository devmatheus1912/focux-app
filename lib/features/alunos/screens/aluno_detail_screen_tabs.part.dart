part of 'aluno_detail_screen.dart';

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
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.6))),
        ),
        child: Semantics(
          container: true,
          label: 'Abas do perfil do aluno',
          child: TabBar(
            controller: tabController,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: mute,
            indicatorWeight: 2.5,
            dividerColor: Colors.transparent,
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

class _AlunoDetailOperacaoTab extends StatelessWidget {
  const _AlunoDetailOperacaoTab({
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.proximaAcao360,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    required this.onPassword,
    required this.onEdit,
    required this.onMessage,
    required this.onEvolve,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onMessage;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final financeRisk =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (financeRisk) ...[
          FxPremiumEntrance(
            delay: Duration.zero,
            child: _AlunoFinanceiroRiskBanner(alunoId: alunoId, isDark: isDark),
          ),
          const SizedBox(height: TokensStrip.s4),
        ],
        FxPremiumEntrance(
          delay: Duration(milliseconds: financeRisk ? 40 : 0),
          child: _AlunoFollowUpCard(aluno: aluno, isDark: isDark),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: Duration(milliseconds: financeRisk ? 80 : 40),
          child: _Aluno360CopilotCard(
            aluno: aluno,
            resumoAsync: autonomiaResumoAsync,
            proximaAcao360: proximaAcao360,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: Duration(milliseconds: financeRisk ? 120 : 80),
          child: _AlunoOperationalStatusSection(
            aluno: aluno,
            isDark: isDark,
            primary: primary,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: Duration(milliseconds: financeRisk ? 160 : 120),
          child: _AlunoRecoveryInsightCard(
            recoveryAsync: recoveryAsync,
            isDark: isDark,
            primary: primary,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: Duration(milliseconds: financeRisk ? 200 : 160),
          child: _StudentQuickActions(
            aluno: aluno,
            isDark: isDark,
            primary: primary,
            onPassword: onPassword,
            onEdit: onEdit,
            onMessage: onMessage,
            onEvolve: onEvolve,
          ),
        ),
      ],
    );
  }
}

class _AlunoDetailEvolucaoTab extends StatelessWidget {
  const _AlunoDetailEvolucaoTab({
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
    required this.evolucaoAsync,
    required this.timeline360Async,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final AsyncValue<List<Timeline360Event>> timeline360Async;

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
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: const Duration(milliseconds: 40),
          child: _Aluno360TimelineCard(
            aluno: aluno,
            timelineApiAsync: timeline360Async,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxPremiumEntrance(
          delay: const Duration(milliseconds: 80),
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
    required this.isDark,
  });

  final Aluno aluno;
  final int alunoId;
  final ProximaAcaoResumo? proximaAcao360;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final line = ShellChrome.of(context).line;
    final openActionsAsync = ref.watch(alunoOpenIaActionsProvider(alunoId));
    FilaAcaoResumo? existingOpenTask;
    for (final item in openActionsAsync.valueOrNull ?? const <FilaAcaoResumo>[]) {
      if (item.status.toUpperCase() != 'ABERTO') continue;
      final source = (item.source ?? '').toUpperCase();
      if (item.tipo == 'IA_COPILOTO' ||
          source == 'ALUNO_360' ||
          (item.sourceMode ?? '').toUpperCase() == 'ALUNO_360' ||
          item.createdFromInsight) {
        existingOpenTask = item;
        break;
      }
    }

    final followUpDue =
        aluno.followUpDate != null &&
        !aluno.followUpDate!.isAfter(DateTime.now());

    final acao360 = proximaAcao360?.acao.trim() ?? '';
    final lower = acao360.toLowerCase();
    final preferChat =
        followUpDue ||
        lower.contains('contato') ||
        lower.contains('chat') ||
        lower.contains('mensagem');

    void openChat() {
      context.push('/alunos/$alunoId/chat', extra: aluno.nome);
    }

    void openCommandCenter() {
      context.push('/dashboard/command-center/copiloto');
    }

    final hasOpenTask = existingOpenTask != null;
    final primaryLabel =
        hasOpenTask
            ? 'Ver tarefa'
            : preferChat
                ? 'Abrir chat'
                : 'Ver tarefa';
    final primaryIcon =
        hasOpenTask || !preferChat
            ? Icons.open_in_new_rounded
            : Icons.chat_bubble_outline_rounded;
    final VoidCallback onPrimary =
        hasOpenTask
            ? openCommandCenter
            : preferChat
                ? openChat
                : openCommandCenter;

    return SafeArea(
      top: false,
      child: Semantics(
        container: true,
        label: 'Ações rápidas da aba operação',
        child: Container(
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
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: primaryLabel,
                child: FxLiquidPrimaryButton(
                icon: primaryIcon,
                label: primaryLabel,
                onPressed: onPrimary,
                ),
              ),
            ),
            if (!preferChat && !hasOpenTask) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Abrir chat com aluno',
                child: SizedBox(
                width: 112,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: openChat,
                  icon: Icon(Icons.chat_bubble_outline, size: 16, color: primary),
                  label: Text(
                    'Chat',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary.withValues(alpha: 0.28)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
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

class _AlunoDetailFerramentasTab extends ConsumerWidget {
  const _AlunoDetailFerramentasTab({
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.perfilCompletion,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final int perfilCompletion;

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
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: crossAxisCount == 2 ? 1.45 : 1.1,
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 10,
          childAspectRatio: 2.55,
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
        ),
      ],
    );
  }
}
