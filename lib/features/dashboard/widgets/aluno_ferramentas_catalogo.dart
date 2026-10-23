import 'package:flutter/material.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_view.dart';

enum AlunoFerramentaGrupo { treino, saude, relacao, conta }

class AlunoFerramentaAcao {
  const AlunoFerramentaAcao({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final AlunoFerramentaGrupo group;
}

/// As rotas que o dock não cobre. Anamnese fica no grupo Conta do Perfil.
List<AlunoFerramentaAcao> alunoFerramentas(S s) => [
  AlunoFerramentaAcao(
    icon: Icons.fitness_center,
    title: s.alunoFerramentaTreinosTitulo,
    subtitle: s.alunoFerramentaTreinosDetalhe,
    route: '/checkin/treinos',
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.trending_up_rounded,
    title: s.alunoFerramentaHistoricoTitulo,
    subtitle: s.alunoFerramentaHistoricoDetalhe,
    route: '/checkin/historico',
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.calendar_month_outlined,
    title: s.alunoFerramentaAgendaTitulo,
    subtitle: s.alunoFerramentaAgendaDetalhe,
    route: '/agenda/aluno',
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.videocam_outlined,
    title: s.alunoFerramentaFeedbackVideoTitulo,
    subtitle: s.alunoFerramentaFeedbackVideoDetalhe,
    route: alunoFeedbackVideoRoute,
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.flag_outlined,
    title: s.alunoFerramentaDesafiosTitulo,
    subtitle: s.alunoFerramentaDesafiosDetalhe,
    route: '/aluno/desafios',
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.groups_outlined,
    title: s.alunoFerramentaAulasGrupoTitulo,
    subtitle: s.alunoFerramentaAulasGrupoDetalhe,
    route: '/aluno/grupo-aulas',
    group: AlunoFerramentaGrupo.treino,
  ),
  AlunoFerramentaAcao(
    icon: Icons.track_changes_outlined,
    title: s.alunoFerramentaHabitosTitulo,
    subtitle: s.alunoFerramentaHabitosDetalhe,
    route: '/aluno/habitos',
    group: AlunoFerramentaGrupo.saude,
  ),
  AlunoFerramentaAcao(
    icon: Icons.route_outlined,
    title: s.alunoFerramentaTrilhasTitulo,
    subtitle: s.alunoFerramentaTrilhasDetalhe,
    route: '/aluno/trilhas',
    group: AlunoFerramentaGrupo.saude,
  ),
  AlunoFerramentaAcao(
    icon: Icons.watch_outlined,
    title: s.alunoFerramentaProntidaoTitulo,
    subtitle: s.alunoFerramentaProntidaoDetalhe,
    route: '/saude',
    group: AlunoFerramentaGrupo.saude,
  ),
  AlunoFerramentaAcao(
    icon: Icons.chat_bubble_outline,
    title: s.alunoFerramentaPersonalTitulo,
    subtitle: s.alunoFerramentaPersonalDetalhe,
    route: '/chat/aluno',
    group: AlunoFerramentaGrupo.relacao,
  ),
  AlunoFerramentaAcao(
    icon: Icons.dynamic_feed_outlined,
    title: s.alunoFerramentaFeedTitulo,
    subtitle: s.alunoFerramentaFeedDetalhe,
    route: '/feed/aluno',
    group: AlunoFerramentaGrupo.relacao,
  ),
  AlunoFerramentaAcao(
    icon: Icons.rate_review_outlined,
    title: s.alunoFerramentaDepoimentosTitulo,
    subtitle: s.alunoFerramentaDepoimentosDetalhe,
    route: '/depoimentos-aluno',
    group: AlunoFerramentaGrupo.relacao,
  ),
  AlunoFerramentaAcao(
    icon: Icons.payments_outlined,
    title: s.alunoFerramentaFinanceiroTitulo,
    subtitle: s.alunoFerramentaFinanceiroDetalhe,
    route: '/financeiro/aluno',
    group: AlunoFerramentaGrupo.conta,
  ),
  AlunoFerramentaAcao(
    icon: Icons.autorenew,
    title: s.alunoFerramentaRecorrenciaTitulo,
    subtitle: s.alunoFerramentaRecorrenciaDetalhe,
    route: '/aluno/recorrencia',
    group: AlunoFerramentaGrupo.conta,
  ),
];

/// Grupos do catálogo no Perfil. Some o grupo inteiro quando o plano esconde tudo.
class AlunoFerramentasCatalogo extends StatelessWidget {
  const AlunoFerramentasCatalogo({super.key, required this.liberada});

  final bool Function(String route) liberada;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final tools = alunoFerramentas(s).where((t) => liberada(t.route)).toList();
    final sections = <(AlunoFerramentaGrupo, String)>[
      (AlunoFerramentaGrupo.treino, s.alunoFerramentasGrupoTreino),
      (AlunoFerramentaGrupo.saude, s.alunoFerramentasGrupoSaude),
      (AlunoFerramentaGrupo.relacao, s.alunoFerramentasGrupoRelacao),
      (AlunoFerramentaGrupo.conta, s.alunoFerramentasGrupoConta),
    ];
    final grupos = <Widget>[];
    for (final (group, header) in sections) {
      final items = tools.where((t) => t.group == group).toList(growable: false);
      if (items.isEmpty) continue;
      grupos.add(
        Padding(
          padding: const EdgeInsets.only(bottom: TokensStrip.s3),
          child: FxSettingsGroup(
            header: header,
            children: [
              for (var i = 0; i < items.length; i++)
                FxSettingsTile(
                  icon: items[i].icon,
                  label: items[i].title,
                  value: items[i].subtitle,
                  mute: chrome.mute,
                  line: chrome.line,
                  showDivider: i < items.length - 1,
                  onTap: () => openAlunoRoute(context, items[i].route),
                ),
            ],
          ),
        ),
      );
    }
    if (grupos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TokensStrip.s4),
        ...grupos,
      ],
    );
  }
}
