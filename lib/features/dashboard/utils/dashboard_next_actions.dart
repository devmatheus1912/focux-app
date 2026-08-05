import '../data/command_action_item.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';
import 'dashboard_screen_helpers.dart';

export '../data/command_action_item.dart';

/// Aluno em risco para enriquecer o sheet (ações por aluno).
typedef DashboardRiskStudentRef = ({int id, String nome});

/// Monta a fila curada de próximas ações da Home / Central de Comando.
///
/// Ordem fixa de impacto: **P0 risco → P1 cobrança → mensagens → resto**.
/// Mesmo com [hideRiskSummary] (Atenção já cobre o radar), o P0 permanece
/// na Central para alinhar com o Foco do dia — só muda o copy.
///
/// [riskOwnedByDayFocus]: o Foco do dia já é o narrador único do risco
/// (banner + P0 na Central); o card aqui não repete a contagem — só chama
/// para a ação.
List<CommandActionItem> buildDashboardNextActions({
  required List<FilaAcaoResumo> filaAcoes,
  required int unreadCount,
  required int alunosRisco,
  required int cobrancasPendentes,
  required int agendaHoje,
  required bool hideRiskSummary,
  required bool isCommandPreparing,
  bool riskOwnedByDayFocus = false,
  int maxItems = 6,
}) {
  final copilotAcoes = filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').toList();
  final filaNaoCopilot =
      filaAcoes.where((a) => a.tipo != 'IA_COPILOTO').toList();
  final queueAction =
      filaNaoCopilot.isEmpty
          ? null
          : (hideRiskSummary &&
                  isRiskEchoCopy(
                    '${filaNaoCopilot.first.titulo} ${filaNaoCopilot.first.descricao}',
                  )
              ? null
              : CommandActionItem(
                icon: 'zap',
                title: 'Executar próxima ação',
                subtitle: dashboardFormatActionCopy(
                  filaNaoCopilot.first.descricao,
                ),
                route:
                    filaNaoCopilot.first.acaoUrl.startsWith('/')
                        ? filaNaoCopilot.first.acaoUrl
                        : '/dashboard/personal',
                tone: CommandActionTone.primary,
              ));

  final nextActions = <CommandActionItem>[
    if (alunosRisco > 0)
      CommandActionItem(
        icon:
            riskOwnedByDayFocus
                ? 'route'
                : hideRiskSummary
                ? 'zap'
                : 'alert-triangle',
        title:
            riskOwnedByDayFocus
                ? 'Abrir fila de retenção'
                : hideRiskSummary
                ? 'Recuperar alunos em risco'
                : 'Contato hoje',
        subtitle:
            riskOwnedByDayFocus
                ? 'Trabalhar o P0 agora'
                : hideRiskSummary
                ? '$alunosRisco aluno${alunosRisco == 1 ? '' : 's'} com risco de abandono'
                : '$alunosRisco no radar · risco, inadimplência ou pausa no treino',
        route:
            (riskOwnedByDayFocus || hideRiskSummary)
                ? '/retencao'
                : '/alunos?filtro=contato',
        tone: CommandActionTone.hot,
        priorityBadge: 'P0',
      ),
    if (cobrancasPendentes > 0)
      CommandActionItem(
        icon: 'dollar-sign',
        title: 'Cobrar pendências',
        subtitle:
            '$cobrancasPendentes mensalidade${cobrancasPendentes == 1 ? '' : 's'} no radar',
        route: '/financeiro',
        tone: CommandActionTone.money,
        priorityBadge: 'P1',
      ),
    if (unreadCount > 0)
      CommandActionItem(
        icon: 'message-circle',
        title: 'Responder mensagens',
        subtitle:
            '$unreadCount conversa${unreadCount == 1 ? '' : 's'} aguardando',
        route: '/chat/inbox',
        tone: CommandActionTone.hot,
        priorityBadge: 'P1',
      ),
    if (copilotAcoes.isNotEmpty)
      CommandActionItem(
        icon: 'zap',
        title: dashboardFormatActionCopy(
          copilotAcoes.first.titulo.isNotEmpty
              ? copilotAcoes.first.titulo
              : 'Revisar tarefa IA',
        ),
        subtitle: dashboardFormatActionCopy(copilotAcoes.first.descricao),
        route: '/dashboard/command-center/copiloto',
        tone: CommandActionTone.primary,
      ),
    if (queueAction != null) queueAction,
    if (agendaHoje > 0)
      CommandActionItem(
        icon: 'calendar',
        title: 'Preparar agenda',
        subtitle: '$agendaHoje compromisso${agendaHoje == 1 ? '' : 's'} hoje',
        route: '/agenda',
        tone: CommandActionTone.primary,
      ),
  ];

  if (nextActions.isEmpty && !isCommandPreparing) {
    nextActions.add(
      const CommandActionItem(
        icon: 'plus',
        title: 'Criar próxima oportunidade',
        subtitle: 'Cadastre aluno, treino ou lead antes do pico do dia',
        route: '/alunos/novo',
        tone: CommandActionTone.primary,
      ),
    );
  }

  if (nextActions.length <= maxItems) return nextActions;
  return nextActions.take(maxItems).toList(growable: false);
}

CommandActionItem sheetItemFromFila(FilaAcaoResumo action) {
  final rawTitle = action.titulo.isNotEmpty ? action.titulo : 'Prioridade';
  final radarName = dashboardRadarStudentName(rawTitle);
  final isRadar = radarName != null;
  final badge = dashboardPriorityBadgeLabel(
    prioridade: action.prioridade,
    sla: action.sla,
    ctaLabel: action.ctaLabel,
  );
  return CommandActionItem(
    icon: 'zap',
    title: radarName ?? dashboardFormatActionCopy(rawTitle),
    subtitle: dashboardFormatCountCopy(action.descricao),
    route:
        action.acaoUrl.startsWith('/') ? action.acaoUrl : '/dashboard/personal',
    tone: CommandActionTone.primary,
    isRadarStudent: isRadar,
    priorityBadge: badge,
  );
}

int dashboardActionPriorityRank(CommandActionItem item) {
  return switch (item.priorityBadge?.toUpperCase()) {
    'P0' => 0,
    'P1' => 1,
    'P2' => 2,
    'HOJE' => 1,
    _ => 4,
  };
}

bool _isRiskAction(CommandActionItem item) {
  if (item.isRadarStudent) return false;
  final title = item.title.toLowerCase();
  final route = item.route.toLowerCase();
  return item.priorityBadge == 'P0' ||
      route.contains('retencao') ||
      route.contains('alertas') ||
      route.contains('contato') ||
      route.contains('risco') ||
      title.contains('risco') ||
      title.contains('contato hoje') ||
      title.contains('recuperar');
}

bool _isBillingAction(CommandActionItem item) {
  return item.route == '/financeiro' ||
      item.tone == CommandActionTone.money ||
      item.title.toLowerCase().contains('cobrar');
}

/// Sheet só vale a pena se tiver item além do que já está na lista visível.
bool dashboardShouldShowPrioritiesLink({
  required List<CommandActionItem> visible,
  required List<CommandActionItem> sheet,
  required bool isPreparing,
}) {
  if (isPreparing || sheet.isEmpty) return false;
  final visibleKeys = {
    for (final a in visible) '${a.title}|${a.route}',
  };
  return sheet.any((a) => !visibleKeys.contains('${a.title}|${a.route}'));
}

/// Sheet: só impacto extra (não espelha a lista da Home) + ações por aluno.
List<CommandActionItem> buildDashboardSheetActions({
  required List<CommandActionItem> curated,
  required List<FilaAcaoResumo> filaAcoes,
  List<DashboardRiskStudentRef> riskStudents = const [],
}) {
  final seenKeys = <String>{};
  for (final item in curated) {
    seenKeys.add('${item.title}|${item.route}');
  }
  final hasBillingCurated = curated.any(_isBillingAction);
  final hasRiskCurated = curated.any(_isRiskAction);
  // Não repetir P0/P1 já visíveis na Home — só o que a lista curta não cobre.
  final impact = <CommandActionItem>[];
  for (final action in filaAcoes) {
    if (hasBillingCurated &&
        (action.actionKey == 'BILLING_PENDING' || action.tipo == 'COBRANCA')) {
      continue;
    }
    if (hasRiskCurated &&
        (action.actionKey == 'RISK_STUDENTS' ||
            action.tipo == 'RISCO' ||
            action.titulo.toLowerCase().contains('risco'))) {
      continue;
    }
    final item = sheetItemFromFila(action);
    if (item.isRadarStudent) continue;
    final key = '${item.title}|${item.route}';
    if (seenKeys.contains(key)) continue;
    if (hasRiskCurated && _isRiskAction(item)) continue;
    if (hasBillingCurated && _isBillingAction(item)) continue;
    seenKeys.add(key);
    impact.add(item);
  }
  impact.sort((a, b) {
    final byRank = dashboardActionPriorityRank(
      a,
    ).compareTo(dashboardActionPriorityRank(b));
    if (byRank != 0) return byRank;
    return a.title.compareTo(b.title);
  });

  final radar = <CommandActionItem>[];
  for (final student in riskStudents.take(8)) {
    final route = '/alunos/${student.id}';
    final key = '${student.nome}|$route';
    if (seenKeys.contains(key)) continue;
    seenKeys.add(key);
    radar.add(
      CommandActionItem(
        icon: 'users',
        title: student.nome,
        subtitle: 'Contato e retenção',
        route: route,
        tone: CommandActionTone.hot,
        isRadarStudent: true,
        priorityBadge: 'P0',
      ),
    );
  }
  radar.sort((a, b) => a.title.compareTo(b.title));

  return [...impact.take(6), ...radar];
}
