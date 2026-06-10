import '../data/aluno_repository.dart';

String cleanCopilotText(String value) {
  return value
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Fixes common English words leaked by LLMs into PT-BR coach copy.
String sanitizeCopilotIaLanguage(String text) {
  var result = text;
  const leaks = {
    'understanding': 'entender',
    'understand': 'entender',
    'personalized': 'personalizado',
    'customized': 'personalizado',
    'engagement': 'engajamento',
    'workout': 'treino',
    'training': 'treino',
    'schedule': 'cronograma',
    'interruption': 'interrupção',
    'discuss': 'discutir',
    'feedback': 'retorno',
    'follow-up': 'follow-up',
    'motivating': 'motivar',
    'reasons': 'motivos',
    'reason': 'motivo',
    'inactivity': 'inatividade',
  };
  for (final entry in leaks.entries) {
    result = result.replaceAll(
      RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
      entry.value,
    );
  }
  return result;
}

/// Splits copilot prescription footer into scannable segments.
List<String> copilotPrescriptionReasonSegments(String reason) {
  return reason
      .split(' · ')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
}

bool isRedundantCopilotReasonSegment(
  String segment, {
  bool statusMetricsVisible = false,
  bool hideMetricFooter = false,
}) {
  final lower = segment.toLowerCase().trim();
  if (lower.isEmpty) return true;

  final metricNoise =
      lower.contains('aderência') ||
      lower.contains('aderencia') ||
      lower.contains('risco operacional') ||
      lower.contains('sem check-in') ||
      lower.contains('check-ins recentes') ||
      lower.contains('sem registro') ||
      lower.contains('últimos 7 dias') ||
      lower.contains('ultimos 7 dias') ||
      lower.contains('0 de 7') ||
      lower.contains('dias parados') ||
      lower.contains('dias sem treino') ||
      lower.contains('inativid') ||
      (lower.contains('priorize contato') && lower.contains('ader'));

  if (metricNoise || hideMetricFooter) return true;

  if (!statusMetricsVisible) return false;

  return lower.startsWith('priorize contato') ||
      lower.contains('evoluir o plano') ||
      lower.contains('contato direto hoje');
}

/// Hides metric bullets already visible in the status grid (non-focus mode).
String sanitizeCopilotPrescriptionReason(
  String reason, {
  required bool statusMetricsVisible,
  bool hideMetricFooter = false,
}) {
  if (reason.trim().isEmpty) return '';
  if (hideMetricFooter) return '';
  if (!statusMetricsVisible) return reason.trim();
  final segments =
      copilotPrescriptionReasonSegments(reason)
          .where(
            (segment) => !isRedundantCopilotReasonSegment(
              segment,
              statusMetricsVisible: true,
            ),
          )
          .toList(growable: false);
  if (segments.isEmpty) return '';
  return segments.join(' · ');
}

/// Strips LLM preambles so UI shows the actionable sentence, not boilerplate.
String normalizeIaCopilotAcao(String raw) {
  var text = sanitizeCopilotIaLanguage(cleanCopilotText(raw));
  if (text.isEmpty) return text;

  const preambles = [
    r'^a próxima ação mais importante é\s*',
    r'^a próxima ação mais importante:\s*',
    r'^a próxima melhor ação é\s*',
    r'^próxima ação:\s*',
    r'^sugiro que você\s*',
    r'^recomendo que você\s*',
    r'^recomendo\s*',
  ];
  for (final pattern in preambles) {
    text = text.replaceFirst(RegExp(pattern, caseSensitive: false), '');
  }
  text = text.trim();
  if (text.isEmpty) return cleanCopilotText(raw);
  return text[0].toUpperCase() + text.substring(1);
}

String humanizeCopilotMotivoDiasFragment(int dias, {String kind = 'atividade'}) {
  if (dias >= 90) return 'sem registro recente';
  if (dias == 0) return kind == 'treino' ? 'treinou hoje' : 'sem pausa hoje';
  if (dias == 1) {
    return kind == 'treino' ? '1 dia sem treino' : '1 dia parado';
  }
  return kind == 'treino' ? '$dias dias sem treino' : '$dias dias parados';
}

String _humanizeCopilotMotivoDiasInText(String text) {
  var result = text.replaceAllMapped(
    RegExp(r'(\d+) dia\(s\) sem (atividade|treino)', caseSensitive: false),
    (match) {
      final dias = int.tryParse(match.group(1)!) ?? 0;
      final kind = match.group(2)!.toLowerCase() == 'treino' ? 'treino' : 'atividade';
      return humanizeCopilotMotivoDiasFragment(dias, kind: kind);
    },
  );
  result = result.replaceAllMapped(
    RegExp(r'[Úú]ltima atividade há (\d+) dia\(s\)', caseSensitive: false),
    (match) {
      final dias = int.tryParse(match.group(1)!) ?? 0;
      return humanizeCopilotMotivoDiasFragment(dias, kind: 'treino');
    },
  );
  return result;
}

String formatCopilotIaMotivo(String motivo) {
  final trimmed = motivo.trim();
  if (trimmed.isEmpty) {
    return 'Gerado com base nos sinais atuais do aluno.';
  }

  final match = RegExp(
    r'[Úú]ltima atividade há (\d+) dia\(s\), aderência de (\d+)%',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match != null) {
    final dias = int.tryParse(match.group(1)!) ?? 0;
    final aderencia = match.group(2)!;
    if (dias >= 90) {
      return 'Sem treinos recentes · aderência de $aderencia% nos últimos 30 dias.';
    }
    if (dias == 0) return 'Treinou hoje · aderência de $aderencia%.';
    if (dias == 1) return 'Último treino ontem · aderência de $aderencia%.';
    return 'Sem treino há $dias dias · aderência de $aderencia%.';
  }

  final contatoMatch = RegExp(
    r'Priorize contato · (\d+) dia\(s\) sem atividade · aderência (\d+)%',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (contatoMatch != null) {
    final dias = int.tryParse(contatoMatch.group(1)!) ?? 0;
    final aderencia = contatoMatch.group(2)!;
    final diasLabel = humanizeCopilotMotivoDiasFragment(dias);
    return 'Priorize contato · $diasLabel · aderência $aderencia%.';
  }

  return _humanizeCopilotMotivoDiasInText(trimmed);
}

/// IA/contact copy that reads like a task prompt, not coach UI tone.
bool isRoboticCopilotContactCopy(String text) {
  final lower = normalizeIaCopilotAcao(text).toLowerCase();
  if (lower.isEmpty) return false;
  return lower.contains('entre em contato') ||
      lower.contains('entender os motivos') ||
      lower.contains('entender o motivo') ||
      lower.contains('discutir um plano') ||
      lower.contains('plano de retomada') ||
      lower.contains('paralisa') ||
      lower.contains('paralis') ||
      lower.contains('personalizado') ||
      lower.contains('próxima ação mais importante') ||
      lower.contains('proxima acao mais importante') ||
      lower.contains('incentiv') ||
      (lower.contains('contate') && lower.length > 72) ||
      (lower.contains('contato') && lower.length > 88);
}

String copilotCoachContactPrescription(Aluno aluno, {String? acao}) {
  final firstName =
      aluno.nome.trim().isEmpty ? null : aluno.nome.trim().split(' ').first;
  final lower = acao == null ? '' : normalizeIaCopilotAcao(acao).toLowerCase();
  if (lower.contains('check-in') || lower.contains('check in')) {
    return firstName == null
        ? 'Pedir check-in e entender como foi a semana.'
        : 'Pedir check-in com $firstName e entender como foi a semana.';
  }
  return firstName == null
      ? 'Retomar contato e checar como está o treino.'
      : 'Retomar contato com $firstName e checar como está o treino.';
}

String copilotChatActionLabel(String acao) {
  final lower = normalizeIaCopilotAcao(acao).toLowerCase();
  if (lower.contains('whatsapp')) return 'Enviar WhatsApp';
  if (lower.contains('mensagem')) return 'Enviar mensagem';
  if (copilotAcaoMencionaWearable(acao)) return 'Retomar contato';
  if (lower.contains('contato') ||
      lower.contains('contate') ||
      lower.contains('contatar') ||
      lower.contains('contactar') ||
      lower.contains('retomar') ||
      lower.contains('inativid') ||
      lower.contains('incentiv')) {
    return 'Retomar contato';
  }
  return 'Abrir chat';
}

bool copilotAcaoMencionaWearable(String acao) {
  final lower = normalizeIaCopilotAcao(acao).toLowerCase();
  return lower.contains('wearable') ||
      lower.contains('apple health') ||
      lower.contains('google fit') ||
      lower.contains('sincroniz') ||
      lower.contains(' sync') ||
      lower.startsWith('sync') ||
      lower.contains('garmin') ||
      lower.contains('terra');
}
