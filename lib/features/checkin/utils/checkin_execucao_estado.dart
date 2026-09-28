import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';

/// Início do cronômetro da sessão; sessão zumbi (8h+) recomeça do zero.
DateTime checkinInicioCronometro(String? iniciadoEm, DateTime agora) {
  final inicio =
      iniciadoEm == null ? null : DateTime.tryParse(iniciadoEm)?.toLocal();
  if (inicio == null || agora.difference(inicio).inHours >= 8) return agora;
  return inicio;
}

/// Série pendente no estado local: conta como feita até o servidor confirmar.
ExecucaoExercicio checkinAplicarSerieLocal(
  ExecucaoExercicio ee,
  CheckinSeriePendente serie,
) {
  final feitas =
      serie.numero > ee.seriesFeitas ? serie.numero : ee.seriesFeitas;
  final total = ee.series;
  final local = ExecucaoSerie(
    id: 0,
    numero: serie.numero,
    cargaKg: serie.cargaKg,
    repeticoes: serie.repeticoes,
    feedback: serie.feedback,
    rpe: serie.rpe,
    dor: serie.dor,
  );
  final detalhes = [
    ...ee.seriesDetalhes.where((s) => s.numero != serie.numero),
    local,
  ]..sort((a, b) => a.numero.compareTo(b.numero));
  return ee.copyWith(
    seriesFeitas: feitas,
    concluido: total != null && feitas >= total,
    feedback: serie.feedback,
    rpe: serie.rpe,
    dor: serie.dor,
    seriesDetalhes: detalhes,
  );
}

ExecucaoTreino checkinComExercicio(
  ExecucaoTreino treino,
  ExecucaoExercicio atualizado,
) {
  return ExecucaoTreino(
    id: treino.id,
    treinoId: treino.treinoId,
    treinoNome: treino.treinoNome,
    status: treino.status,
    iniciadoEm: treino.iniciadoEm,
    concluidoEm: treino.concluidoEm,
    dataInicio: treino.dataInicio,
    dataFim: treino.dataFim,
    evolucoesCarga: treino.evolucoesCarga,
    evolucoesPerformance: treino.evolucoesPerformance,
    exerciciosCount: treino.exerciciosCount,
    exercicios: [
      for (final e in treino.exercicios) e.id == atualizado.id ? atualizado : e,
    ],
  );
}

/// Reaplica a fila desta execução sobre o que o servidor devolveu.
ExecucaoTreino checkinAplicarPendentes(
  ExecucaoTreino treino,
  List<CheckinSeriePendente> fila,
) {
  var atual = treino;
  for (final serie in fila) {
    if (serie.execucaoId != treino.id) continue;
    for (final ee in atual.exercicios) {
      if (ee.treinoExercicioId == serie.treinoExercicioId) {
        atual = checkinComExercicio(atual, checkinAplicarSerieLocal(ee, serie));
        break;
      }
    }
  }
  return atual;
}

int checkinPendentesDaExecucao(List<CheckinSeriePendente> fila, int? id) =>
    id == null ? 0 : fila.where((p) => p.execucaoId == id).length;

int checkinExerciciosFaltando(List<ExecucaoExercicio> exercicios) =>
    exercicios.where((e) => !e.concluido).length;

/// Performance primeiro; builds antigos do backend só mandam carga.
List<EvolucaoPerformance> checkinEvolucoesParaCelebrar(
  ExecucaoTreino concluida,
) {
  if (concluida.evolucoesPerformance.isNotEmpty) {
    return concluida.evolucoesPerformance;
  }
  return [
    for (final e in concluida.evolucoesCarga)
      EvolucaoPerformance(
        tipo: 'CARGA',
        exercicioId: e.exercicioId,
        exercicioNome: e.exercicioNome,
        valorAnterior: e.cargaAnteriorKg,
        valorAtual: e.cargaAtualKg,
        diferenca: e.diferencaKg,
        percentual: e.percentual,
        unidade: 'kg',
        mensagem: e.mensagem,
      ),
  ];
}
