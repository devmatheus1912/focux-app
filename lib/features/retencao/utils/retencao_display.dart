import '../data/retencao_repository.dart';

String retencaoRiscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

int retencaoRiscoSortOrder(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 0,
  'MEDIO' || 'MÉDIO' => 1,
  'BAIXO' => 2,
  _ => 3,
};

bool retencaoRiscoAlto(String risco) => risco.trim().toUpperCase() == 'ALTO';

bool retencaoRiscoMedio(String risco) {
  final r = risco.trim().toUpperCase();
  return r == 'MEDIO' || r == 'MÉDIO';
}

List<RetencaoAlunoScore> sortedRetencaoScores(List<RetencaoAlunoScore> scores) {
  final copy = List<RetencaoAlunoScore>.from(scores);
  copy.sort((a, b) {
    final risk = retencaoRiscoSortOrder(
      a.riscoChurn,
    ).compareTo(retencaoRiscoSortOrder(b.riscoChurn));
    if (risk != 0) return risk;
    return b.scoreAtual.compareTo(a.scoreAtual);
  });
  return copy;
}

RetencaoAlunoScore? firstAltoRetencao(List<RetencaoAlunoScore> scores) {
  for (final s in scores) {
    if (retencaoRiscoAlto(s.riscoChurn)) return s;
  }
  return null;
}

({int alto, int medio, int saudavel}) retencaoRiskCounts(
  List<RetencaoAlunoScore> scores,
) {
  var alto = 0;
  var medio = 0;
  var saudavel = 0;
  for (final s in scores) {
    if (retencaoRiscoAlto(s.riscoChurn)) {
      alto += 1;
    } else if (retencaoRiscoMedio(s.riscoChurn)) {
      medio += 1;
    } else if (s.riscoChurn.trim().toUpperCase() == 'BAIXO') {
      saudavel += 1;
    }
  }
  return (alto: alto, medio: medio, saudavel: saudavel);
}
