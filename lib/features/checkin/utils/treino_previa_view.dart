import '../../treinos/utils/grupos_de_serie.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/utils/aluno_home_texts.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';
import '../data/checkin_repository.dart';
import '../models/treino_previa.dart';
import 'checkin_execucao_display.dart';
import 'treino_ficha_status.dart';

/// Rodapé da prévia. Vem do agregado da Home, não da prévia.
enum TreinoPreviaSituacao {
  disponivel,

  /// Outra ficha com sessão aberta: Iniciar leva à execução, que trata o 409.
  outraSessaoAberta,
  emAndamento,
  concluidoHoje,
  emPreparacao,
}

/// Null quando a Home ainda não carregou ou não lista a ficha: só Iniciar.
TreinoPreviaSituacao? treinoPreviaSituacao({
  required int treinoId,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required DateTime now,
}) {
  ExecucaoTreino? ficha;
  for (final t in treinos) {
    if (t.treinoId == treinoId) ficha = t;
  }
  if (ficha == null) return null;
  if (normalizeTreinoStatus(ficha.status) == treinoStatusEmAndamento) {
    return TreinoPreviaSituacao.emAndamento;
  }
  if (isTreinoAguardandoLiberacao(ficha)) {
    return TreinoPreviaSituacao.emPreparacao;
  }
  if (treinoSessaoEmAndamento(treinos) != null) {
    return TreinoPreviaSituacao.outraSessaoAberta;
  }
  if (treinoConcluidoHoje(historico, now: now)?.treinoId == treinoId) {
    return TreinoPreviaSituacao.concluidoHoje;
  }
  return TreinoPreviaSituacao.disponivel;
}

/// "Já fiz" só onde grava algo novo: ficha livre e ainda não feita hoje.
bool treinoPreviaMostraJaFiz(TreinoPreviaSituacao? s) =>
    s == TreinoPreviaSituacao.disponivel;

/// "6 exercícios · Até 23 de out."
String treinoPreviaCabecalho(S s, TreinoPrevia p, {required DateTime hoje}) {
  final prazo = alunoPrazoTexto(
    s,
    TreinoAtribuicaoPrazo.parseIsoDate(p.dataFim),
    hoje: hoje,
  );
  return [
    s.treinosExercicios(p.exercicios.length),
    if (prazo != null) prazo,
  ].join(' · ');
}

/// "3 × 10–12 · 20 kg"; com grupos, o mesmo resumo do editor ("2 aquec. ·
/// 3 × 12-15 · 2 back-off"). O descanso fica para a execução.
String treinoPreviaPrescricao(S s, TreinoPreviaExercicio e) {
  final grupos = e.seriesPrescritas.isEmpty
      ? null
      : resumoDosGrupos(e.seriesPrescritas);
  if (grupos != null) {
    return grupos.replaceAll(RegExp(r' · \d+ s(?= ·|$)'), '');
  }
  final carga = e.cargaKg;
  return [
    if (e.series != null || (e.repeticoes?.trim().isNotEmpty ?? false))
      checkinSeriesRepsLabel(e.series, e.repeticoes),
    if (carga != null && carga > 0) checkinCargaLabel(carga)!,
  ].join(' · ');
}
