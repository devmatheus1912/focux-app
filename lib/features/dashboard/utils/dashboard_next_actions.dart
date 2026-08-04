import '../data/command_action_item.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';
import 'dashboard_screen_helpers.dart';

export '../data/command_action_item.dart';

/// Monta a fila curada de próximas ações da Home / Central de Comando.
List<CommandActionItem> buildDashboardNextActions({
  required List<FilaAcaoResumo> filaAcoes,
  required int unreadCount,
  required int alunosRisco,
  required int cobrancasPendentes,
  required int agendaHoje,
  required bool hideRiskSummary,
  required bool isCommandPreparing,
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
    if (alunosRisco > 0 && !hideRiskSummary)
      CommandActionItem(
        icon: 'alert-triangle',
        title: 'Contato hoje',
        subtitle:
            '$alunosRisco no radar · risco, inadimplência ou pausa no treino',
        route: '/alunos?filtro=contato',
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

List<CommandActionItem> buildDashboardSheetActions({
  required List<CommandActionItem> curated,
  required List<FilaAcaoResumo> filaAcoes,
}) {
  final seenKeys = <String>{};
  for (final item in curated) {
    seenKeys.add('${item.title}|${item.route}');
  }
  final hasBillingCurated = curated.any(
    (item) =>
        item.route == '/financeiro' || item.tone == CommandActionTone.money,
  );
  final hasRiskCurated = curated.any(
    (item) =>
        item.tone == CommandActionTone.hot &&
        (item.route.contains('alertas') ||
            item.route.contains('contato') ||
            item.route.contains('risco')),
  );
  final merged = <CommandActionItem>[...curated];
  for (final action in filaAcoes) {
    if (hasBillingCurated &&
        (action.actionKey == 'BILLING_PENDING' || action.tipo == 'COBRANCA')) {
      continue;
    }
    if (hasRiskCurated &&
        (action.actionKey == 'RISK_STUDENTS' || action.tipo == 'RISCO')) {
      continue;
    }
    final item = sheetItemFromFila(action);
    final key = '${item.title}|${item.route}';
    if (seenKeys.contains(key)) continue;
    seenKeys.add(key);
    merged.add(item);
  }
  return merged.take(12).toList();
}
