import '../data/evolucao_repository.dart';

const engajamentoPeriodos = [30, 60, 90];

String engajamentoPeriodoLabel(int dias) => '$dias dias';

String engajamentoTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
      return 'Treino';
    case 'CHECKIN_CONCLUIDO':
      return 'Check-in';
    case 'MEDIDA':
      return 'Medida';
    case 'MENSAGEM':
      return 'Mensagem';
    case '':
      return 'Evento';
    default:
      return tipo!.trim();
  }
}

String engajamentoFxIcon(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return 'dumbbell';
    case 'MEDIDA':
      return 'trend';
    case 'MENSAGEM':
      return 'chat';
    default:
      return 'calendar';
  }
}

String engajamentoWhenLabel(String dataHora) {
  try {
    final dt = DateTime.parse(dataHora).toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  } catch (_) {
    final raw = dataHora.trim();
    if (raw.length >= 16) return raw.substring(0, 16);
    return raw.isEmpty ? '—' : raw;
  }
}

String engajamentoEventoLabel(String? descricao, String? tipo) {
  final text = descricao?.trim();
  if (text != null && text.isNotEmpty) return text;
  return engajamentoTipoLabel(tipo);
}

String engajamentoEventoSubtitle({
  required String? tipo,
  required String dataHora,
}) =>
    '${engajamentoTipoLabel(tipo)} · ${engajamentoWhenLabel(dataHora)}';

String engajamentoHubSubtitle({
  required String alunoNome,
  required int dias,
  String? freshness,
}) {
  final nome = alunoNome.trim().isEmpty ? 'Aluno' : alunoNome.trim();
  final parts = <String>[nome, engajamentoPeriodoLabel(dias)];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String engajamentoEventosMetricHint(int count, int dias) {
  if (count <= 0) return 'Nada em ${engajamentoPeriodoLabel(dias)}';
  return engajamentoPeriodoLabel(dias);
}

bool _engajamentoTipoTreino(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return true;
    default:
      return false;
  }
}

int engajamentoTreinosCount(Iterable<EventoEngajamento> eventos) =>
    eventos.where((e) => _engajamentoTipoTreino(e.tipo)).length;

int engajamentoMensagensCount(Iterable<EventoEngajamento> eventos) =>
    eventos.where((e) => e.tipo.trim().toUpperCase() == 'MENSAGEM').length;

String engajamentoUltimoHint(Iterable<EventoEngajamento> eventos) {
  EventoEngajamento? last;
  for (final evento in eventos) {
    if (last == null || evento.dataHora.compareTo(last.dataHora) > 0) {
      last = evento;
    }
  }
  if (last == null) return 'Nenhum evento na janela';
  return '${engajamentoTipoLabel(last.tipo)} · ${engajamentoWhenLabel(last.dataHora)}';
}

String? engajamentoEventoRota(String? tipo, int alunoId) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'MENSAGEM':
      return '/alunos/$alunoId/chat';
    case 'MEDIDA':
      return '/alunos/$alunoId/evolucao';
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return '/alunos/$alunoId/treinos-list';
    default:
      return null;
  }
}
