part of 'aluno_dashboard_screen.dart';

enum _StudentToolGroup { treino, saude, relacao, conta }

class _StudentToolsSection extends StatelessWidget {
  const _StudentToolsSection();

  static const tools = <_StudentToolAction>[
    _StudentToolAction(
      icon: Icons.fitness_center,
      title: 'Treinos',
      subtitle: 'Check-ins e histórico',
      route: '/checkin/treinos',
      group: _StudentToolGroup.treino,
      featured: true,
    ),
    _StudentToolAction(
      icon: Icons.trending_up_rounded,
      title: 'Histórico',
      subtitle: 'Medidas e treinos',
      route: '/checkin/historico',
      group: _StudentToolGroup.treino,
    ),
    _StudentToolAction(
      icon: Icons.calendar_month_outlined,
      title: 'Agenda',
      subtitle: 'Horários',
      route: '/agenda/aluno',
      group: _StudentToolGroup.treino,
      featured: true,
    ),
    _StudentToolAction(
      icon: Icons.assignment_outlined,
      title: 'Anamnese',
      subtitle: 'Ficha de saúde',
      route: '/aluno/anamnese',
      group: _StudentToolGroup.saude,
      featured: true,
    ),
    _StudentToolAction(
      icon: Icons.track_changes_outlined,
      title: 'Hábitos',
      subtitle: 'Metas diárias',
      route: '/aluno/habitos',
      group: _StudentToolGroup.saude,
    ),
    _StudentToolAction(
      icon: Icons.route_outlined,
      title: 'Trilhas',
      subtitle: 'Metas e progresso',
      route: '/aluno/trilhas',
      group: _StudentToolGroup.saude,
    ),
    _StudentToolAction(
      icon: Icons.watch_outlined,
      title: 'Prontidão',
      subtitle: 'Wearables',
      route: '/saude',
      group: _StudentToolGroup.saude,
    ),
    _StudentToolAction(
      icon: Icons.chat_bubble_outline,
      title: 'Personal',
      subtitle: 'Chat direto',
      route: '/chat/aluno',
      group: _StudentToolGroup.relacao,
      featured: true,
    ),
    _StudentToolAction(
      icon: Icons.dynamic_feed_outlined,
      title: 'Feed',
      subtitle: 'Novidades do personal',
      route: '/feed/aluno',
      group: _StudentToolGroup.relacao,
    ),
    _StudentToolAction(
      icon: Icons.rate_review_outlined,
      title: 'Depoimentos',
      subtitle: 'Avalie seu personal',
      route: '/depoimentos-aluno',
      group: _StudentToolGroup.relacao,
    ),
    _StudentToolAction(
      icon: Icons.payments_outlined,
      title: 'Financeiro',
      subtitle: 'Pagamentos',
      route: '/financeiro/aluno',
      group: _StudentToolGroup.conta,
    ),
    _StudentToolAction(
      icon: Icons.autorenew,
      title: 'Pagamento automático',
      subtitle: 'Se o personal ativou',
      route: '/aluno/recorrencia',
      group: _StudentToolGroup.conta,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final featured = tools.where((t) => t.featured).toList(growable: false);
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Atalhos do dia',
          actionLabel: 'Ver catálogo',
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
  final primary = Theme.of(context).colorScheme.primary;
  final chrome = ShellChrome.of(context);
  const sections = <(_StudentToolGroup, String)>[
    (_StudentToolGroup.treino, 'Treino'),
    (_StudentToolGroup.saude, 'Saúde'),
    (_StudentToolGroup.relacao, 'Relação'),
    (_StudentToolGroup.conta, 'Conta'),
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
              title: 'Ferramentas',
              subtitle: 'Atalhos da conta.',
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
