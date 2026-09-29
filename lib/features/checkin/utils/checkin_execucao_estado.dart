import '../../../core/api/api_error.dart';
import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';

/// Retry de concluir num backend anterior ao concluir idempotente: o 400
/// "já foi concluído" quer dizer que a primeira tentativa entrou.
bool checkinConclusaoJaFeita(Object erro) {
  final api = ApiError.from(erro);
  if (api?.status != 400) return false;
  final texto = (api!.mensagem ?? '').toLowerCase();
  return texto.contains('já foi concluído') || texto.contains('ja foi concluido');
}

/// Concluir tolerante a retry. `null` = já estava concluído, sem resposta
/// de evolução para mostrar.
Future<ExecucaoTreino?> checkinConcluir(
  Future<ExecucaoTreino> Function() concluir,
) async {
  try {
    return await concluir();
  } catch (e) {
    if (checkinConclusaoJaFeita(e)) return null;
    rethrow;
  }
}

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

bool checkinPodeRegistrar(ExecucaoExercicio ee) {
  final total = ee.series ?? 0;
  return !ee.concluido && !(total > 0 && ee.seriesFeitas >= total);
}

enum CheckinRodape { nenhum, registrar, finalizar }

/// Zona do polegar: a ação da série atual; Finalizar só quando tudo foi
/// feito. Descanso mantém o rodapé que já tinha (nenhum).
CheckinRodape checkinRodape({
  required bool descansando,
  required bool tudoFeito,
  required ExecucaoExercicio? atual,
}) {
  if (descansando) return CheckinRodape.nenhum;
  if (tudoFeito) return CheckinRodape.finalizar;
  if (atual != null && checkinPodeRegistrar(atual)) {
    return CheckinRodape.registrar;
  }
  return CheckinRodape.nenhum;
}

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
