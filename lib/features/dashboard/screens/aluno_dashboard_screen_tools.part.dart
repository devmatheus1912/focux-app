part of 'aluno_dashboard_screen.dart';

class _StudentToolsSection extends StatelessWidget {
  const _StudentToolsSection();

  @override
  Widget build(BuildContext context) {
    const tools = <_StudentToolAction>[
      _StudentToolAction(
        icon: Icons.fitness_center,
        title: 'Treinos',
        subtitle: 'Check-ins e histórico',
        route: '/checkin/treinos',
        featured: true,
      ),
      _StudentToolAction(
        icon: Icons.assignment_outlined,
        title: 'Anamnese',
        subtitle: 'Ficha de saúde',
        route: '/aluno/anamnese',
        featured: true,
      ),
      _StudentToolAction(
        icon: Icons.track_changes_outlined,
        title: 'Hábitos',
        subtitle: 'Metas diárias',
        route: '/aluno/habitos',
      ),
      _StudentToolAction(
        icon: Icons.flag_outlined,
        title: 'Desafios',
        subtitle: 'Campanhas e ranking',
        route: '/aluno/desafios',
      ),
      _StudentToolAction(
        icon: Icons.route_outlined,
        title: 'Trilhas',
        subtitle: 'Metas e progresso',
        route: '/aluno/trilhas',
      ),
      _StudentToolAction(
        icon: Icons.chat_bubble_outline,
        title: 'Personal',
        subtitle: 'Chat direto',
        route: '/chat/aluno',
        featured: true,
      ),
      _StudentToolAction(
        icon: Icons.watch_outlined,
        title: 'Prontidão',
        subtitle: 'Wearables',
        route: '/saude',
      ),
      _StudentToolAction(
        icon: Icons.emoji_events_outlined,
        title: 'Evolução',
        subtitle: 'Streak e badges',
        route: '/gamificacao',
      ),
      _StudentToolAction(
        icon: Icons.trending_up_rounded,
        title: 'Histórico',
        subtitle: 'Medidas e treinos',
        route: '/checkin/historico',
      ),
      _StudentToolAction(
        icon: Icons.groups_outlined,
        title: 'Aulas grupo',
        subtitle: 'Inscreva-se',
        route: '/aluno/grupo-aulas',
      ),
      _StudentToolAction(
        icon: Icons.videocam_outlined,
        title: 'Form check',
        subtitle: 'Análise IA',
        route: '/aluno/form-check',
      ),
      _StudentToolAction(
        icon: Icons.autorenew,
        title: 'Assinatura',
        subtitle: 'Recorrência',
        route: '/aluno/recorrencia',
      ),
      _StudentToolAction(
        icon: Icons.smart_toy_outlined,
        title: 'IA',
        subtitle: 'Rotina guiada',
        route: '/ia/aluno',
      ),
      _StudentToolAction(
        icon: Icons.payments_outlined,
        title: 'Financeiro',
        subtitle: 'Pagamentos',
        route: '/financeiro/aluno',
      ),
      _StudentToolAction(
        icon: Icons.calendar_month_outlined,
        title: 'Agenda',
        subtitle: 'Horários',
        route: '/agenda/aluno',
        featured: true,
      ),
    ];

    final featured = tools.where((t) => t.featured).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Atalhos do dia',
          actionLabel: 'Ver catálogo',
          onAction: () => _showAlunoToolsCatalog(context, tools: tools),
        ),
        const SizedBox(height: TokensStrip.s2),
        for (final tool in featured)
          FxSatelliteListTile(
            title: tool.title,
            subtitle: Text(tool.subtitle),
            onTap: () => context.push(tool.route),
          ),
      ],
    );
  }
}

void _showAlunoToolsCatalog(
  BuildContext context, {
  required List<_StudentToolAction> tools,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      return FxHomeSheetSurface(
        isDark: Theme.of(ctx).brightness == Brightness.dark,
        child: ListView(
          shrinkWrap: true,
          children: [
            FxHomeSheetHeader(
              title: 'Ferramentas',
              subtitle: 'Acesso ao restante da conta.',
              leading: Icon(Icons.apps_outlined, size: 18, color: primary),
            ),
            for (final tool in tools)
              FxSatelliteListTile(
                title: tool.title,
                subtitle: Text(tool.subtitle),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(tool.route);
                },
              ),
          ],
        ),
      );
    },
  );
}

class _StudentToolAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool featured;

  const _StudentToolAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.featured = false,
  });
}

/// Banner no Meu Treino quando a anamnese pede ação do aluno.
class _AlunoAnamneseCta extends ConsumerWidget {
  const _AlunoAnamneseCta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(minhaAnamneseProvider);
    return async.when(
      data: (a) {
        if (!a.alunoDevePreencher) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
              onTap: () => context.push('/aluno/anamnese'),
              child: AnamneseStatusBanner(
                title: anamneseAlunoCtaTitle(a),
                body: anamneseAlunoCtaBody(a),
                tone: a.isPrecisaAtestado
                    ? AnamneseBannerTone.warn
                    : AnamneseBannerTone.info,
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
