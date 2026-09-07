import '../../../core/utils/fx_utils.dart';

enum HistoricoStatusChip { todos, concluido, andamento }

String historicoCountLabel(int count) {
  if (count == 1) return '1 treino';
  return '$count treinos';
}

bool historicoConcluido(String status) =>
    status.trim().toUpperCase() == 'CONCLUIDO';

String historicoStatusLabel(String status) =>
    historicoConcluido(status) ? 'Concluído' : 'Em andamento';

bool historicoMatchesQuery({
  required String treinoNome,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return treinoNome.toLowerCase().contains(q);
}

bool historicoMatchesChip({
  required String status,
  required HistoricoStatusChip chip,
}) {
  switch (chip) {
    case HistoricoStatusChip.todos:
      return true;
    case HistoricoStatusChip.concluido:
      return historicoConcluido(status);
    case HistoricoStatusChip.andamento:
      return !historicoConcluido(status);
  }
}

String? historicoStatusQuery(HistoricoStatusChip chip) {
  switch (chip) {
    case HistoricoStatusChip.todos:
      return null;
    case HistoricoStatusChip.concluido:
      return 'CONCLUIDO';
    case HistoricoStatusChip.andamento:
      return 'EM_ANDAMENTO';
  }
}

String historicoChipLabel(HistoricoStatusChip chip) {
  switch (chip) {
    case HistoricoStatusChip.todos:
      return 'Todos';
    case HistoricoStatusChip.concluido:
      return 'Concluído';
    case HistoricoStatusChip.andamento:
      return 'Em andamento';
  }
}

String historicoDateLabel(String? iniciadoEm) {
  final raw = iniciadoEm?.trim();
  if (raw == null || raw.isEmpty) return '';
  try {
    return fxDateFull(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}
