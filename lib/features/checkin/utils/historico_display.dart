import '../../../core/utils/fx_utils.dart';
import '../data/checkin_repository.dart';

enum HistoricoStatusChip { todos, concluido, andamento }

String historicoCountLabel(int count) {
  if (count == 1) return '1 treino';
  return '$count treinos';
}

bool historicoConcluido(String status) =>
    status.trim().toUpperCase() == 'CONCLUIDO';

String historicoStatusLabel(String status) =>
    historicoConcluido(status) ? 'Concluído' : 'Em andamento';

/// Status honesto quando a sessão foi marcada concluída sem séries.
String historicoStatusDisplayLabel({
  required String status,
  required int seriesFeitas,
}) {
  if (historicoConcluido(status) && seriesFeitas <= 0) {
    return 'Concluído sem séries';
  }
  return historicoStatusLabel(status);
}

String historicoExerciciosMetricHint(int total) {
  if (total <= 0) return 'sem exercícios';
  if (total == 1) return '1 exercício';
  return '$total exercícios';
}

/// Agrupa "Todos" em Em andamento → Concluído (ordem de lista).
({List<ExecucaoTreino> andamento, List<ExecucaoTreino> concluidos})
historicoGroupByStatus(List<ExecucaoTreino> items) {
  final andamento = <ExecucaoTreino>[];
  final concluidos = <ExecucaoTreino>[];
  for (final item in items) {
    if (historicoConcluido(item.status)) {
      concluidos.add(item);
    } else {
      andamento.add(item);
    }
  }
  return (andamento: andamento, concluidos: concluidos);
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

class HistoricoListCluster {
  const HistoricoListCluster({required this.newest, required this.count});

  final ExecucaoTreino newest;
  final int count;
}

/// Agrupa sessões consecutivas do mesmo plano e status (§12.1).
List<HistoricoListCluster> historicoCollapseSamePlan(
  List<ExecucaoTreino> items,
) {
  final out = <HistoricoListCluster>[];
  for (final item in items) {
    if (out.isNotEmpty &&
        out.last.newest.treinoNome == item.treinoNome &&
        historicoConcluido(out.last.newest.status) ==
            historicoConcluido(item.status)) {
      final last = out.removeLast();
      out.add(HistoricoListCluster(newest: last.newest, count: last.count + 1));
    } else {
      out.add(HistoricoListCluster(newest: item, count: 1));
    }
  }
  return out;
}

String historicoClusterSubtitle({
  required String dateLabel,
  required int count,
}) {
  if (count <= 1) return dateLabel;
  if (dateLabel.isEmpty) {
    return count == 1 ? '1 sessão' : '$count sessões';
  }
  return '$count sessões · $dateLabel';
}

int historicoEmptySeriesCount(Iterable<int> seriesFeitas) =>
    seriesFeitas.where((n) => n <= 0).length;

int historicoEmptySeriesFromExercicios(Iterable<ExecucaoExercicio> items) {
  return historicoEmptySeriesCount(
    items.map(
      (item) => historicoSeriesFeitasEfetivas(
        seriesFeitas: item.seriesFeitas,
        seriesDetalhesCount: item.seriesDetalhes.length,
      ),
    ),
  );
}

String historicoEmptySeriesSummary(int count) {
  if (count == 1) return '1 exercício sem séries';
  return '$count exercícios sem séries';
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
          ? (seriesFeitas > 0 ? 'Parcial' : 'Sem séries')
          : 'Pendente';
  final parts = <String>[
    if ((carga ?? '').trim().isNotEmpty) carga!.trim(),
    seriesLabel,
    if (rpe != null) 'RPE $rpe',
    if (dor) 'Dor',
    statusLabel,
  ];
  return parts.join(' · ');
}

/// Preferência: `seriesFeitas`; se 0, conta detalhes persistidos (anti-drift).
int historicoSeriesFeitasEfetivas({
  required int seriesFeitas,
  required int seriesDetalhesCount,
}) {
  if (seriesFeitas > 0) return seriesFeitas;
  return seriesDetalhesCount;
}

bool historicoExercicioConcluidoEfetivo({
  required bool concluido,
  required int seriesFeitas,
  int? series,
}) {
  if (concluido) return true;
  if (series == null || series <= 0) return seriesFeitas > 0;
  return seriesFeitas >= series;
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
