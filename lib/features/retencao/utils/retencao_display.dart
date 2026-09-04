import '../data/retencao_repository.dart';

String retencaoRiscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

bool retencaoRiscoAlto(String risco) => risco.trim().toUpperCase() == 'ALTO';

const retencaoComoCalculamos =
    'Score 0–100: alto abaixo de 40, médio 40–69, saudável 70 ou mais. O catálogo pagina a base e busca pelo nome.';

RetencaoAlunoScore? firstAltoRetencao(List<RetencaoAlunoScore> scores) {
  for (final s in scores) {
    if (retencaoRiscoAlto(s.riscoChurn)) return s;
  }
  return null;
}
