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
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onMessage;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlunoFollowUpCard(aluno: aluno, isDark: isDark),
        const SizedBox(height: TokensStrip.s4),
        _Aluno360CopilotCard(
          aluno: aluno,
          resumoAsync: autonomiaResumoAsync,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s4),
        _AlunoOperationalStatusSection(
          aluno: aluno,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(height: TokensStrip.s4),
        _AlunoRecoveryInsightCard(
          recoveryAsync: recoveryAsync,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(height: TokensStrip.s4),
        _StudentQuickActions(
          aluno: aluno,
          isDark: isDark,
          primary: primary,
          onPassword: onPassword,
          onEdit: onEdit,
          onMessage: onMessage,
          onEvolve: onEvolve,
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
        _Aluno360TimelineCard(
          aluno: aluno,
          timelineApiAsync: timeline360Async,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s4),
        _AlunoWeightActivityCard(
          aluno: aluno,
          alunoId: alunoId,
          isDark: isDark,
          ink: ink,
        ),
      ],
    );
  }
}

class _AlunoDetailFerramentasTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final altura = formatAlturaDisplay(aluno.altura);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _MeasurementCard(
              label: 'Idade',
              value: (aluno.idade ?? '--').toString(),
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
              value: '--',
              unit: '%',
              isDark: isDark,
            ),
            _MeasurementCard(
              label: 'M. Magra',
              value: '--',
              unit: 'kg',
              isDark: isDark,
            ),
          ],
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
              sub: 'Sem dados recentes',
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
              sub: 'Sem medida',
              badge: 'Pendente',
              isDark: isDark,
              onTap: () => context.push(
                '/alunos/$alunoId/evolucao',
                extra: aluno.nome,
              ),
            ),
            _ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Aderência',
              sub: 'Sem dados',
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
              onTap: () => context.push('/financeiro'),
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
