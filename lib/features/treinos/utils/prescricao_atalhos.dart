/// Atalhos de um toque para a prescrição, por bloco do treino.
library;

/// Repetições (ou tempo) mais comuns de cada bloco.
List<String> atalhosRepeticoes(String bloco) => switch (bloco) {
  'AQUECIMENTO' => const ['10', '12', '15', '20'],
  'ALONGAMENTO' => const ['20s', '30s', '45s', '60s'],
  _ => const ['6-8', '8-12', '12-15', '15-20'],
};

/// Descanso em segundos.
List<int> atalhosDescansoSeg(String bloco) => switch (bloco) {
  'AQUECIMENTO' => const [15, 30, 45, 60],
  'ALONGAMENTO' => const [0, 10, 15, 30],
  _ => const [30, 60, 90, 120],
};

/// Valores oferecidos em "Outro" para o descanso.
const opcoesDescansoSeg = [
  0, 10, 15, 30, 45, 60, 75, 90, 105, 120, 150, 180, 240, 300,
];

/// O valor atual de repetições é um dos atalhos? (senão "Outro" aparece marcado)
bool repeticoesEhAtalho(String bloco, String atual) =>
    atalhosRepeticoes(bloco).contains(atual.trim());

bool descansoEhAtalho(String bloco, int atual) =>
    atalhosDescansoSeg(bloco).contains(atual);

/// "Mais detalhes" abre sozinho quando algum já tem valor: nada some do
/// personal que já usa carga, RPE, observações, superset ou dropset.
bool maisDetalhesPreenchidos({
  required String carga,
  required String rpe,
  required String observacoes,
  required String tipoSerie,
}) =>
    carga.trim().isNotEmpty ||
    rpe.trim().isNotEmpty ||
    observacoes.trim().isNotEmpty ||
    tipoSerie.toUpperCase() != 'NORMAL';

