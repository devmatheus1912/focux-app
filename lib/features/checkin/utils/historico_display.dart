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

String historicoDetalhePath(int execucaoId) => '/checkin/historico/$execucaoId';

String historicoStickyLabel(String status) =>
    historicoConcluido(status) ? 'Treinar de novo' : 'Continuar treino';

String historicoDetalheSubtitle({
  required String status,
  String? iniciadoEm,
}) {
  final parts = <String>[
    historicoStatusLabel(status),
    if (historicoDateLabel(iniciadoEm).isNotEmpty)
      historicoDateLabel(iniciadoEm),
  ];
  return parts.join(' · ');
}

int historicoExerciciosConcluidos(Iterable<bool> done) =>
    done.where((item) => item).length;

String historicoExerciciosMetric({required int done, required int total}) =>
    '$done/$total';

String historicoPrMetric(int count) => '$count';

String historicoPrHint(int count) =>
    count == 0 ? 'Sem recorde nesta sessão' : (count == 1 ? '1 recorde' : '$count recordes');

String? historicoDuracaoLabel(
  String? iniciadoEm,
  String? concluidoEm, {
  bool sessaoAberta = false,
}) {
  final start = DateTime.tryParse((iniciadoEm ?? '').trim());
  if (start == null) return null;
  final endRaw = (concluidoEm ?? '').trim();
  final end = endRaw.isEmpty ? null : DateTime.tryParse(endRaw);
  // Sessão fechada sem concluidoEm → não inventa duração até "agora" (vira 13h+).
  if (end == null && !sessaoAberta) return null;
  final stop = end ?? DateTime.now();
  final minutes = stop.difference(start).inMinutes;
  if (minutes < 0) return null;
  // Relógio esquecido / sessão zumbi — não mostra absurdo.
  if (minutes > 8 * 60) return null;
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}

String historicoPrLine({
  required String exercicioNome,
  required String mensagem,
}) {
  final name = exercicioNome.trim();
  final note = mensagem.trim();
  if (name.isEmpty) return note;
  if (note.isEmpty) return name;
  return '$name · $note';
}

String historicoExercicioSubtitle({
  required int seriesFeitas,
  int? series,
  required bool concluido,
  bool sessaoConcluida = false,
  String? carga,
  int? rpe,
  bool dor = false,
}) {
  final seriesLabel =
      series == null ? '$seriesFeitas séries' : '$seriesFeitas/$series séries';
  final statusLabel = concluido
      ? 'Feito'
      : sessaoConcluida
          ? (seriesFeitas > 0 ? 'Parcial' : 'Não feito')
          : 'Pendente';
  final parts = <String>[
    seriesLabel,
    if ((carga ?? '').trim().isNotEmpty) carga!.trim(),
    if (rpe != null) 'RPE $rpe',
    if (dor) 'Dor',
    statusLabel,
  ];
  return parts.join(' · ');
}

const historicoSecaoExercicios = 'exercicios';
const historicoSecaoRecordes = 'recordes';
const historicoSecaoNotas = 'notas';

const historicoDetalheSecoes = <({String value, String label})>[
  (value: historicoSecaoExercicios, label: 'Exercícios'),
  (value: historicoSecaoRecordes, label: 'Recordes'),
  (value: historicoSecaoNotas, label: 'Notas'),
];

String? historicoNotaLine({
  String? observacoes,
  String? feedback,
}) {
  final obs = observacoes?.trim() ?? '';
  final note = feedback?.trim() ?? '';
  if (obs.isEmpty && note.isEmpty) return null;
  if (obs.isEmpty) return note;
  if (note.isEmpty) return obs;
  return '$obs · $note';
}

String historicoNotasEmpty() => 'Nenhuma nota nesta sessão';

int historicoRecordesCount({required int prs, required int cargas}) =>
    prs + cargas;

String historicoRecordesEmpty() => 'Nenhum recorde nesta sessão';
