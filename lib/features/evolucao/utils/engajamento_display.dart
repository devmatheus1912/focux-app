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
    case 'EM_ANDAMENTO':
      return 'Em andamento';
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

String engajamentoStatusLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'EM_ANDAMENTO':
      return 'Em andamento';
    case 'CONCLUIDO':
      return 'Concluído';
    case 'CANCELADO':
      return 'Cancelado';
    case '':
      return '';
    default:
      return status!.trim();
  }
}

String engajamentoEventoLabel(String? descricao, String? tipo) {
  final text = descricao?.trim();
  if (text != null && text.isNotEmpty) {
    return text
        .replaceAll(' - ', ' · ')
        .replaceAll('EM_ANDAMENTO', 'em andamento')
        .replaceAll('CONCLUIDO', 'concluído')
        .replaceAll('CANCELADO', 'cancelado')
        .replaceAll('_', ' ');
  }
  return engajamentoTipoLabel(tipo);
}

/// Tipo do evento como apoio; nulo quando o título já é o próprio tipo.
String? engajamentoEventoSubtitle({
  required String? tipo,
  required String titulo,
}) {
  final label = engajamentoTipoLabel(tipo);
  return label.toLowerCase() == titulo.trim().toLowerCase() ? null : label;
}

String engajamentoHoraLabel(String dataHora) {
  final dt = DateTime.tryParse(dataHora)?.toLocal();
  if (dt == null) return '—';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String engajamentoDiaLabel(String dataHora, {DateTime? now}) {
  final dt = DateTime.tryParse(dataHora)?.toLocal();
  if (dt == null) return 'Sem data';
  final ref = now ?? DateTime.now();
  final hoje = DateTime(ref.year, ref.month, ref.day);
  final dia = DateTime(dt.year, dt.month, dt.day);
  final diff = hoje.difference(dia).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d/$m';
}

typedef EngajamentoLinha = ({String? dia, EventoEngajamento? evento});

/// Achata eventos (já ordenados do mais recente) em cabeçalho de dia + itens.
List<EngajamentoLinha> engajamentoLinhasPorDia(
  List<EventoEngajamento> eventos, {
  DateTime? now,
}) {
  final linhas = <EngajamentoLinha>[];
  String? atual;
  for (final evento in eventos) {
    final dia = engajamentoDiaLabel(evento.dataHora, now: now);
    if (dia != atual) {
      linhas.add((dia: dia, evento: null));
      atual = dia;
    }
    linhas.add((dia: null, evento: evento));
  }
  return linhas;
}

/// Subtítulo do hub: só o período (nome fica no [FxHubHeader]).
String engajamentoHubSubtitle({required int dias}) =>
    engajamentoPeriodoLabel(dias);

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

String engajamentoUltimoValue(Iterable<EventoEngajamento> eventos) {
  EventoEngajamento? last;
  for (final evento in eventos) {
    if (last == null || evento.dataHora.compareTo(last.dataHora) > 0) {
      last = evento;
    }
  }
  if (last == null) return '—';
  return engajamentoTipoLabel(last.tipo);
}

String engajamentoUltimoHint(Iterable<EventoEngajamento> eventos) {
  EventoEngajamento? last;
  for (final evento in eventos) {
    if (last == null || evento.dataHora.compareTo(last.dataHora) > 0) {
      last = evento;
    }
  }
  if (last == null) return 'Nenhum evento na janela';
  return engajamentoWhenLabel(last.dataHora);
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
