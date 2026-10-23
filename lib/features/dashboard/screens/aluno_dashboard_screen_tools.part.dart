part of 'aluno_dashboard_screen.dart';

enum _StudentToolGroup { treino, saude, relacao, conta }

List<_StudentToolAction> _alunoTools(S s) => [
  _StudentToolAction(
    icon: Icons.fitness_center,
    title: s.alunoFerramentaTreinosTitulo,
    subtitle: s.alunoFerramentaTreinosDetalhe,
    route: '/checkin/treinos',
    group: _StudentToolGroup.treino,
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
  ),
  _StudentToolAction(
    icon: Icons.videocam_outlined,
    title: s.alunoFerramentaFeedbackVideoTitulo,
    subtitle: s.alunoFerramentaFeedbackVideoDetalhe,
    route: alunoFeedbackVideoRoute,
    group: _StudentToolGroup.treino,
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

/// Atalhos ([AlunoHomeView.atalhos]) + catálogo do que o plano do
/// personal libera.
void abrirHomeAlunoMais(
  BuildContext context, {
  required AlunoHomeView view,
  required AlunoDashboardHomeBundle home,
  required DateTime hoje,
  required ValueChanged<AlunoPendencia> onPendencia,
  required void Function(AlunoPendencia) onPendenciaShown,
}) {
  final s = S.of(context);
  final tools =
      _alunoTools(s).where((t) => view.ferramentaLiberada(t.route)).toList();
  _showAlunoToolsCatalog(
    context,
    tools: tools,
    antes: [
      if (view.pendencias.isNotEmpty)
        AlunoPendenciasBlock(
          pendencias: view.pendencias,
          hoje: hoje,
          onTap: onPendencia,
          onShown: onPendenciaShown,
        ),
      if (view.semanaVisivel) AlunoWeekSummaryCard(summary: view.semana),
      if (view.prontidaoVisivel)
        AlunoRecoveryCard(
          snapshot: home.recovery,
          mostrarDica: !view.prontidaoBaixa,
        ),
      if (view.jaTreinou)
        AlunoEvolutionCard(
          destaque: home.destaqueExercicio,
          ultimoRecorde: home.recordes.isEmpty ? null : home.recordes.first,
          recordesMes: home.recordesMes,
        ),
      if (view.ofertas.isNotEmpty) AlunoUpsellCarousel(ofertas: view.ofertas),
      if (view.aviso == AlunoHomeAviso.coach && view.coach.isNotEmpty)
        CoachProativoCard(mensagens: view.coach),
    ],
  );
}

void _showAlunoToolsCatalog(
  BuildContext context, {
  required List<_StudentToolAction> tools,
  List<Widget> antes = const [],
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
            ...antes,
            for (final (group, header) in sections)
              _alunoCatalogGroup(
                context: context,
                sheetContext: ctx,
                header: header,
                items: tools
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
              openAlunoRoute(context, items[i].route);
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

  const _StudentToolAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
  });
}
