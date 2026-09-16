import '../data/checkin_repository.dart';

/// Status de ficha devolvidos por `meus-treinos` / `dashboard/aluno/home`.
const treinoStatusDisponivel = 'DISPONIVEL';
const treinoStatusAguardandoLiberacao = 'AGUARDANDO_LIBERACAO';
const treinoStatusEmAndamento = 'EM_ANDAMENTO';
const treinoStatusConcluido = 'CONCLUIDO';

String normalizeTreinoStatus(String? status) =>
    (status ?? '').trim().toUpperCase();

/// Ficha atribuída sem exercícios — não oferecer Iniciar.
bool isTreinoAguardandoLiberacao(ExecucaoTreino treino) {
  final status = normalizeTreinoStatus(treino.status);
  if (status == treinoStatusAguardandoLiberacao) return true;
  if (status == treinoStatusDisponivel ||
      status == treinoStatusEmAndamento ||
      status == treinoStatusConcluido) {
    return false;
  }
  // Legado: status genérico + lista vazia = ainda em preparação.
  return treino.exercicios.isEmpty;
}

/// Pode iniciar / retomar execução.
bool isTreinoDisponivelParaIniciar(ExecucaoTreino treino) {
  final status = normalizeTreinoStatus(treino.status);
  if (status == treinoStatusAguardandoLiberacao) return false;
  if (status == treinoStatusDisponivel || status == treinoStatusEmAndamento) {
    return true;
  }
  if (status == treinoStatusConcluido) return false;
  // Legado: tem exercícios ativos.
  return treino.exercicios.isNotEmpty;
}

List<ExecucaoTreino> treinosProntosParaIniciar(List<ExecucaoTreino> treinos) =>
    treinos.where(isTreinoDisponivelParaIniciar).toList(growable: false);

/// Próximo treino do dia: retoma EM_ANDAMENTO; senão gira após o último concluído.
ExecucaoTreino? proximoTreinoParaHoje({
  required List<ExecucaoTreino> treinos,
  List<ExecucaoTreino> historico = const [],
}) {
  final startable = treinosProntosParaIniciar(treinos);
  if (startable.isEmpty) return null;

  for (final t in startable) {
    if (normalizeTreinoStatus(t.status) == treinoStatusEmAndamento) {
      return t;
    }
  }

  ExecucaoTreino? lastDone;
  DateTime? lastDt;
  for (final h in historico) {
    if (normalizeTreinoStatus(h.status) != treinoStatusConcluido) continue;
    final raw = h.concluidoEm ?? h.iniciadoEm;
    if (raw == null) continue;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) continue;
    if (lastDt == null || dt.isAfter(lastDt)) {
      lastDt = dt;
      lastDone = h;
    }
  }
  if (lastDone == null) return startable.first;

  final ids = treinos.map((t) => t.treinoId).toList(growable: false);
  final idx = ids.indexOf(lastDone.treinoId);
  if (idx < 0) return startable.first;

  for (var step = 1; step <= treinos.length; step++) {
    final cand = treinos[(idx + step) % treinos.length];
    if (isTreinoDisponivelParaIniciar(cand)) return cand;
  }
  return startable.first;
}

/// Startable first — job is find & start, not pipeline noise.
List<ExecucaoTreino> treinosOrdenadosStartFirst(List<ExecucaoTreino> treinos) {
  final pronto = <ExecucaoTreino>[];
  final resto = <ExecucaoTreino>[];
  for (final t in treinos) {
    if (isTreinoDisponivelParaIniciar(t)) {
      pronto.add(t);
    } else {
      resto.add(t);
    }
  }
  return [...pronto, ...resto];
}

/// Conta dias distintos com ≥1 execução `CONCLUIDO` na semana corrente.
int countUniqueCompletedDaysThisWeek(
  List<ExecucaoTreino> historico, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final startOfWeek = DateTime(
    clock.year,
    clock.month,
    clock.day,
  ).subtract(Duration(days: clock.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final days = <String>{};

  for (final item in historico) {
    if (normalizeTreinoStatus(item.status) != treinoStatusConcluido) continue;
    final raw = item.concluidoEm ?? item.iniciadoEm;
    if (raw == null) continue;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) continue;
    if (dt.isBefore(startOfWeek) || !dt.isBefore(endOfWeek)) continue;
    final key =
        '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    days.add(key);
  }
  return days.length;
}
