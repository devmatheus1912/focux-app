import '../../../core/utils/fx_utils.dart';
import '../data/command_action_item.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';
import 'dashboard_screen_helpers.dart';

export '../data/command_action_item.dart';

/// Aluno em risco para enriquecer o sheet (ações por aluno).
typedef DashboardRiskStudentRef =
    ({
      int id,
      String nome,
      String? motivo,
      String? nivelRisco,
      String? proximaAcao,
    });

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
  DashboardRiskStudentRef? leadRiskStudent,
  int maxItems = 6,
}) {
  final copilotAcoes = filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').toList();
  final filaNaoCopilot =
      filaAcoes.where((a) => a.tipo != 'IA_COPILOTO').toList();
  final hasRiskInFila = filaAcoes.any(_isFilaRisk);
  final showRiskP0 = alunosRisco > 0 || hasRiskInFila;
  final queueCandidates =
      filaNaoCopilot.where((a) {
        if (showRiskP0 && _isFilaRisk(a)) return false;
        if (cobrancasPendentes > 0 &&
            (a.actionKey == 'BILLING_PENDING' || a.tipo == 'COBRANCA')) {
          return false;
        }
        return true;
      }).toList();
  final queueAction =
      queueCandidates.isEmpty
          ? null
          : (hideRiskSummary &&
                  isRiskEchoCopy(
                    '${queueCandidates.first.titulo} ${queueCandidates.first.descricao}',
                  )
              ? null
              : CommandActionItem(
                icon: 'zap',
                title: dashboardClampActionCopy(
                  dashboardFormatActionCopy(
                    queueCandidates.first.titulo.isNotEmpty
                        ? queueCandidates.first.titulo
                        : 'Prioridade',
                  ),
                  maxChars: 48,
                ),
                subtitle: _queueActionSubtitle(queueCandidates.first),
                route: dashboardFilaActionRoute(queueCandidates.first),
                tone: CommandActionTone.primary,
                alunoId: queueCandidates.first.alunoId,
                actionKey: queueCandidates.first.actionKey,
              ));

  final nextActions = <CommandActionItem>[
    if (showRiskP0)
      CommandActionItem(
        icon:
            leadRiskStudent != null
                ? 'users'
                : riskOwnedByDayFocus
                ? 'route'
                : hideRiskSummary
                ? 'zap'
                : 'alert-triangle',
        title:
            leadRiskStudent != null
                ? fxTitleCaseName(leadRiskStudent.nome)
                : riskOwnedByDayFocus
                ? 'Abrir fila de retenção'
                : hideRiskSummary
                ? 'Recuperar alunos em risco'
                : 'Contato hoje',
        subtitle:
            leadRiskStudent != null
                ? 'Contato agora'
                : riskOwnedByDayFocus
                ? 'Começar agora'
                : hideRiskSummary
                ? '$alunosRisco aluno${alunosRisco == 1 ? '' : 's'} com risco de abandono'
                : '$alunosRisco no radar · risco, inadimplência ou pausa no treino',
        route:
            leadRiskStudent != null
                ? '/alunos/${leadRiskStudent.id}'
                : (riskOwnedByDayFocus || hideRiskSummary)
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
        title: dashboardClampActionCopy(
          dashboardFormatActionCopy(
            copilotAcoes.first.titulo.isNotEmpty
                ? copilotAcoes.first.titulo
                : 'Revisar tarefa IA',
          ),
          maxChars: 48,
        ),
        subtitle: dashboardClampActionCopy(copilotAcoes.first.descricao),
        route: '/dashboard/command-center/copiloto',
        tone: CommandActionTone.primary,
      ),
    if (queueAction != null && !showRiskP0) queueAction,
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
        subtitle: 'Aluno, treino ou lead antes do pico',
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
    title:
        radarName ??
        dashboardClampActionCopy(
          dashboardFormatActionCopy(rawTitle),
          maxChars: 48,
        ),
    subtitle: dashboardClampActionCopy(action.descricao),
    route: dashboardFilaActionRoute(action),
    tone: CommandActionTone.primary,
    isRadarStudent: isRadar,
    priorityBadge: badge,
    alunoId: action.alunoId,
    actionKey: action.actionKey,
  );
}

/// Deep link honesto: chat-contexto → conversa; agenda-semana → agenda; resto [acaoUrl].
String dashboardFilaActionRoute(FilaAcaoResumo action) {
  final alunoId = action.alunoId;
  if (alunoId != null && _isChatContextoAction(action)) {
    return '/alunos/$alunoId/chat';
  }
  if (_isAgendaSemanaAction(action)) {
    return '/agenda';
  }
  final url = action.acaoUrl;
  if (url.startsWith('/')) return url;
  return '/dashboard/personal';
}

String _queueActionSubtitle(FilaAcaoResumo action) {
  final cta = action.ctaLabel.trim();
  if (cta.isNotEmpty) {
    return dashboardClampActionCopy(cta, maxChars: 42);
  }
  return dashboardClampActionCopy(action.descricao);
}

bool _isChatContextoAction(FilaAcaoResumo action) {
  final key = action.actionKey.toLowerCase();
  if (key.contains('chat-contexto')) return true;
  final url = action.acaoUrl.toLowerCase();
  if (url.contains('/chat')) return true;
  final title = action.titulo.toLowerCase();
  return title.contains('contexto') && title.contains('chat');
}

bool _isAgendaSemanaAction(FilaAcaoResumo action) {
  final key = action.actionKey.toLowerCase();
  if (key.contains('agenda-semana')) return true;
  final title = action.titulo.toLowerCase();
  return title.contains('conferir agenda');
}

/// Ao abrir a agenda a partir do gargalo, conclui a ação na fila.
bool commandActionAutoCompletesOnOpen(CommandActionItem item) {
  final key = item.actionKey?.toLowerCase() ?? '';
  return key.contains('agenda-semana');
}

bool _isFilaRisk(FilaAcaoResumo action) {
  return action.actionKey == 'RISK_STUDENTS' || action.tipo == 'RISCO';
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
  final filaByAluno = <int, FilaAcaoResumo>{};
  for (final action in filaAcoes) {
    final id = action.alunoId;
    if (id == null || filaByAluno.containsKey(id)) continue;
    filaByAluno[id] = action;
  }

  var radarIndex = 0;
  for (final student in riskStudents.take(8)) {
    final displayName = fxTitleCaseName(student.nome);
    final route = '/alunos/${student.id}';
    final key = '$displayName|$route';
    if (seenKeys.contains(key)) continue;
    seenKeys.add(key);
    final fila = filaByAluno[student.id];
    final isLead = radarIndex == 0;
    radar.add(
      CommandActionItem(
        icon: 'users',
        title: displayName,
        subtitle: dashboardRiskStudentSheetSubtitle(
          isLead: isLead,
          motivo: student.motivo,
          nivelRisco: student.nivelRisco,
          proximaAcao: student.proximaAcao,
          filaHint: fila?.descricao,
        ),
        route: route,
        tone: CommandActionTone.hot,
        isRadarStudent: true,
        priorityBadge: isLead ? 'P0' : null,
      ),
    );
    radarIndex++;
  }
  // Mantém ordem de risco do BFF (1º = lead). Não ordenar A–Z.

  return [..._collapseRepeatedImpact(impact.take(6).toList()), ...radar];
}

String _impactTitlePrefix(String title) {
  final cut = title.indexOf(':');
  return cut > 0 ? title.substring(0, cut).trim() : title.trim();
}

List<CommandActionItem> _collapseRepeatedImpact(List<CommandActionItem> items) {
  if (items.length < 2) return items;
  final byPrefix = <String, List<CommandActionItem>>{};
  for (final item in items) {
    final key = _impactTitlePrefix(item.title);
    byPrefix.putIfAbsent(key, () => []).add(item);
  }
  final seen = <String>{};
  final out = <CommandActionItem>[];
  for (final item in items) {
    final key = _impactTitlePrefix(item.title);
    final group = byPrefix[key] ?? const <CommandActionItem>[];
    final uniqueAlunoIds = <int>{
      for (final g in group)
        if (g.alunoId != null) g.alunoId!,
    };
    // Colapsa só com 2+ alunos distintos (não conta linhas do mesmo aluno).
    final uniqueCount = uniqueAlunoIds.isEmpty ? group.length : uniqueAlunoIds.length;
    if (uniqueCount < 2) {
      out.add(item);
      continue;
    }
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(
      CommandActionItem(
        icon: item.icon,
        title: '$key · $uniqueCount',
        subtitle: 'Mesmo gargalo em $uniqueCount alunos',
        route: '/alunos',
        tone: item.tone,
        priorityBadge: item.priorityBadge,
      ),
    );
    // Sheet: alunos afetados como linhas quietas (rota por aluno).
    final emittedAlunos = <int>{};
    for (final g in group) {
      final id = g.alunoId;
      if (id == null || !emittedAlunos.add(id)) continue;
      out.add(
        CommandActionItem(
          icon: 'users',
          title: _collapsedStudentLabel(g),
          subtitle: 'Abrir conversa',
          route: g.route,
          tone: g.tone,
          alunoId: id,
          actionKey: g.actionKey,
        ),
      );
    }
  }
  return out;
}

String _collapsedStudentLabel(CommandActionItem item) {
  final afterColon = item.title.contains(':')
      ? item.title.split(':').skip(1).join(':').trim()
      : '';
  // Título estilo "Gargalo: Ana" — usa o nome curto.
  if (afterColon.isNotEmpty &&
      afterColon.length <= 40 &&
      !afterColon.contains(' ')) {
    return afterColon;
  }
  // Descrição BE crua: "{Nome} clicou N vezes…"
  final sub = item.subtitle.trim();
  final cut = sub.toLowerCase().indexOf(' clicou');
  if (cut > 0) {
    return fxTitleCaseName(sub.substring(0, cut).trim());
  }
  // Após clamp (remove "clicou N vezes em"): sobra "{Nome} …"
  if (afterColon.contains(' ')) {
    final first = sub.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (first.isNotEmpty) {
      final name = first.first.replaceAll(RegExp(r'[.…]+$'), '');
      if (name.length >= 2) return fxTitleCaseName(name);
    }
  }
  if (afterColon.isNotEmpty) return afterColon;
  return item.title;
}
