import '../data/retencao_repository.dart';

String retencaoRiscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

bool retencaoRiscoAlto(String risco) => risco.trim().toUpperCase() == 'ALTO';

RetencaoAlunoScore? firstAltoRetencao(List<RetencaoAlunoScore> scores) {
  for (final s in scores) {
    if (retencaoRiscoAlto(s.riscoChurn)) return s;
  }
  return null;
}
