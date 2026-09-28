import '../data/checkin_repository.dart';

/// Status de ficha devolvidos por `dashboard/aluno/home`.
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
  return treino.totalExercicios == 0;
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
  return treino.totalExercicios > 0;
}

List<ExecucaoTreino> treinosProntosParaIniciar(List<ExecucaoTreino> treinos) =>
    treinos.where(isTreinoDisponivelParaIniciar).toList(growable: false);

ExecucaoTreino? treinoSessaoEmAndamento(List<ExecucaoTreino> treinos) {
  for (final t in treinos) {
    if (normalizeTreinoStatus(t.status) == treinoStatusEmAndamento) {
      return t;
    }
  }
  return null;
}

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

  final lastDone = _ultimoConcluido(historico)?.$1;
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

/// Última execução `CONCLUIDO`, se ela terminou hoje (dia local).
ExecucaoTreino? treinoConcluidoHoje(
  List<ExecucaoTreino> historico, {
  DateTime? now,
}) {
  final ultimo = _ultimoConcluido(historico);
  if (ultimo == null) return null;
  final clock = now ?? DateTime.now();
  final (execucao, dt) = ultimo;
  final mesmoDia =
      dt.year == clock.year && dt.month == clock.month && dt.day == clock.day;
  return mesmoDia ? execucao : null;
}

(ExecucaoTreino, DateTime)? _ultimoConcluido(List<ExecucaoTreino> historico) {
  (ExecucaoTreino, DateTime)? ultimo;
  for (final h in historico) {
    final dt = _concluidoEmLocal(h);
    if (dt == null) continue;
    if (ultimo == null || dt.isAfter(ultimo.$2)) ultimo = (h, dt);
  }
  return ultimo;
}

DateTime? _concluidoEmLocal(ExecucaoTreino item) {
  if (normalizeTreinoStatus(item.status) != treinoStatusConcluido) return null;
  final raw = item.concluidoEm ?? item.iniciadoEm;
  return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
}
