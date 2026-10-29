import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/semana_da_fila.dart';
import '../models/checkin_execucao_models.dart';
import 'treino_ficha_status.dart';

/// Nome previsto para cada dia de treino de hoje até domingo, seguindo a fila
/// a partir do último treino concluído (a mesma regra de "faltar não pula").
/// Hoje entra só se o treino de hoje ainda não foi feito.
Map<int, String> nomesPrevistosDaSemana({
  required RotinaFila rotina,
  required List<ExecucaoTreino> historico,
  required DateTime hoje,
}) {
  final fila = [
    for (final item in rotina.itens)
      if (!item.descanso && item.treinoId != null) item,
  ];
  if (fila.isEmpty) return const {};

  var cursor = _depoisDoUltimo(fila, historico);
  final feitoHoje = treinoConcluidoHoje(historico, now: hoje) != null;
  final previstos = <int, String>{};
  for (final dia in semanaDaFila(rotina)) {
    if (dia.dia < hoje.weekday || (dia.dia == hoje.weekday && feitoHoje)) continue;
    if (dia.sessoes.isEmpty && !dia.segueSequencia) continue;
    previstos[dia.dia] = (fila[cursor % fila.length].nome ?? '').trim();
    cursor++;
  }
  return previstos;
}

/// Posição na fila logo depois do último treino concluído (0 sem histórico).
int _depoisDoUltimo(List<RotinaItem> fila, List<ExecucaoTreino> historico) {
  (int, DateTime)? ultimo;
  for (final item in historico) {
    if (normalizeTreinoStatus(item.status) != treinoStatusConcluido) continue;
    final raw = item.concluidoEm ?? item.iniciadoEm;
    final quando = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (quando == null) continue;
    if (ultimo == null || quando.isAfter(ultimo.$2)) ultimo = (item.treinoId, quando);
  }
  if (ultimo == null) return 0;
  final idx = fila.indexWhere((item) => item.treinoId == ultimo!.$1);
  return idx < 0 ? 0 : idx + 1;
}
