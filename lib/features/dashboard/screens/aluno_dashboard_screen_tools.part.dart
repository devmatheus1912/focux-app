part of 'aluno_dashboard_screen.dart';

enum _StudentToolGroup { treino, saude, relacao, conta }

List<_StudentToolAction> _alunoTools(S s) => [
  _StudentToolAction(
    icon: Icons.fitness_center,
    title: s.alunoFerramentaTreinosTitulo,
    subtitle: s.alunoFerramentaTreinosDetalhe,
    route: '/checkin/treinos',
    group: _StudentToolGroup.treino,
    featured: true,
  ),
  _StudentToolAction(
    icon: Icons.trending_up_rounded,
    title: s.alunoFerramentaHistoricoTitulo,
    subtitle: s.alunoFerramentaHistoricoDetalhe,
    route: '/checkin/historico',
    group: _StudentToolGroup.treino,
  ),
  _StudentToolAction(
    icon: Icons.calendar_month_outlined,
    title: s.alunoFerramentaAgendaTitulo,
    subtitle: s.alunoFerramentaAgendaDetalhe,
    route: '/agenda/aluno',
    group: _StudentToolGroup.treino,
    featured: true,
  ),
  _StudentToolAction(
    icon: Icons.flag_outlined,
    title: s.alunoFerramentaDesafiosTitulo,
    subtitle: s.alunoFerramentaDesafiosDetalhe,
    route: '/aluno/desafios',
    group: _StudentToolGroup.treino,
  ),
  _StudentToolAction(
    icon: Icons.groups_outlined,
    title: s.alunoFerramentaAulasGrupoTitulo,
    subtitle: s.alunoFerramentaAulasGrupoDetalhe,
    route: '/aluno/grupo-aulas',
    group: _StudentToolGroup.treino,
  ),
  _StudentToolAction(
    icon: Icons.assignment_outlined,
    title: s.alunoFerramentaAnamneseTitulo,
    subtitle: s.alunoFerramentaAnamneseDetalhe,
    route: '/aluno/anamnese',
    group: _StudentToolGroup.saude,
    featured: true,
  ),
  _StudentToolAction(
    icon: Icons.track_changes_outlined,
    title: s.alunoFerramentaHabitosTitulo,
    subtitle: s.alunoFerramentaHabitosDetalhe,
    route: '/aluno/habitos',
    group: _StudentToolGroup.saude,
  ),
  _StudentToolAction(
    icon: Icons.route_outlined,
    title: s.alunoFerramentaTrilhasTitulo,
    subtitle: s.alunoFerramentaTrilhasDetalhe,
    route: '/aluno/trilhas',
    group: _StudentToolGroup.saude,
  ),
  _StudentToolAction(
    icon: Icons.watch_outlined,
    title: s.alunoFerramentaProntidaoTitulo,
    subtitle: s.alunoFerramentaProntidaoDetalhe,
    route: '/saude',
    group: _StudentToolGroup.saude,
  ),
  _StudentToolAction(
    icon: Icons.chat_bubble_outline,
    title: s.alunoFerramentaPersonalTitulo,
    subtitle: s.alunoFerramentaPersonalDetalhe,
    route: '/chat/aluno',
    group: _StudentToolGroup.relacao,
  ),
  _StudentToolAction(
    icon: Icons.dynamic_feed_outlined,
    title: s.alunoFerramentaFeedTitulo,
    subtitle: s.alunoFerramentaFeedDetalhe,
    route: '/feed/aluno',
    group: _StudentToolGroup.relacao,
  ),
  _StudentToolAction(
    icon: Icons.rate_review_outlined,
    title: s.alunoFerramentaDepoimentosTitulo,
    subtitle: s.alunoFerramentaDepoimentosDetalhe,
    route: '/depoimentos-aluno',
    group: _StudentToolGroup.relacao,
  ),
  _StudentToolAction(
    icon: Icons.payments_outlined,
    title: s.alunoFerramentaFinanceiroTitulo,
    subtitle: s.alunoFerramentaFinanceiroDetalhe,
    route: '/financeiro/aluno',
    group: _StudentToolGroup.conta,
  ),
  _StudentToolAction(
    icon: Icons.autorenew,
    title: s.alunoFerramentaRecorrenciaTitulo,
    subtitle: s.alunoFerramentaRecorrenciaDetalhe,
    route: '/aluno/recorrencia',
    group: _StudentToolGroup.conta,
  ),
];

class _StudentToolsSection extends StatelessWidget {
  const _StudentToolsSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tools = _alunoTools(s);
    final featured = tools.where((t) => t.featured).toList(growable: false);
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: s.alunoAtalhosTitulo,
          actionLabel: s.alunoAtalhosVerCatalogo,
          onAction: () => _showAlunoToolsCatalog(context, tools: tools),
        ),
        const SizedBox(height: FxSettingsLayout.headerToGroup),
        FxSettingsGroup(
          children: [
            for (var i = 0; i < featured.length; i++)
              FxSettingsTile(
                icon: featured[i].icon,
                label: featured[i].title,
                value: featured[i].subtitle,
                mute: chrome.mute,
                line: chrome.line,
                showDivider: i < featured.length - 1,
                onTap: () => context.push(featured[i].route),
              ),
          ],
        ),
      ],
    );
  }
}

void _showAlunoToolsCatalog(
  BuildContext context, {
  required List<_StudentToolAction> tools,
}) {
  final s = S.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  final chrome = ShellChrome.of(context);
  final sections = <(_StudentToolGroup, String)>[
    (_StudentToolGroup.treino, s.alunoFerramentasGrupoTreino),
    (_StudentToolGroup.saude, s.alunoFerramentasGrupoSaude),
    (_StudentToolGroup.relacao, s.alunoFerramentasGrupoRelacao),
    (_StudentToolGroup.conta, s.alunoFerramentasGrupoConta),
  ];

  showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      return FxHomeSheetSurface(
        isDark: Theme.of(ctx).brightness == Brightness.dark,
        child: ListView(
          shrinkWrap: true,
          children: [
            FxHomeSheetHeader(
              title: s.alunoFerramentasTitulo,
              subtitle: s.alunoFerramentasSubtitulo,
              leading: Icon(Icons.apps_outlined, size: 18, color: primary),
            ),
            for (final (group, header) in sections)
              _alunoCatalogGroup(
                context: context,
                sheetContext: ctx,
                header: header,
                items:
                    tools
                        .where((t) => t.group == group)
                        .toList(growable: false),
                mute: chrome.mute,
                line: chrome.line,
              ),
          ],
        ),
      );
    },
  );
}

Widget _alunoCatalogGroup({
  required BuildContext context,
  required BuildContext sheetContext,
  required String header,
  required List<_StudentToolAction> items,
  required Color mute,
  required Color line,
}) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: TokensStrip.s3),
    child: FxSettingsGroup(
      header: header,
      children: [
        for (var i = 0; i < items.length; i++)
          FxSettingsTile(
            icon: items[i].icon,
            label: items[i].title,
            value: items[i].subtitle,
            mute: mute,
            line: line,
            showDivider: i < items.length - 1,
            onTap: () {
              Navigator.pop(sheetContext);
              context.push(items[i].route);
            },
          ),
      ],
    ),
  );
}

class _StudentToolAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final _StudentToolGroup group;
  final bool featured;

  const _StudentToolAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
    this.featured = false,
  });
}
