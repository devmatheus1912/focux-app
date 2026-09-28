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

/// "3 × 10–12 · 20 kg · descanso 60 s"; só o que o personal prescreveu.
String treinoPreviaPrescricao(S s, TreinoPreviaExercicio e) {
  final carga = e.cargaKg;
  final descanso = e.descansoSegundos;
  return [
    if (e.series != null || (e.repeticoes?.trim().isNotEmpty ?? false))
      checkinSeriesRepsLabel(e.series, e.repeticoes),
    if (carga != null && carga > 0) checkinCargaLabel(carga)!,
    if (descanso != null && descanso > 0) s.treinoPreviaDescanso(descanso),
  ].join(' · ');
}
