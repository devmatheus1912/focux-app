import 'prescricao_serie.dart';

/// Padrão de prescrição ao adicionar um exercício sem memória dele no bloco.
/// Aquecimento e alongamento não herdam a prescrição de hipertrofia.
class PadraoDoBloco {
  const PadraoDoBloco({
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
  });

  final int series;
  final String repeticoes;
  final int descansoSegundos;

  /// Uma linha por série, todas válidas, com a mesma repetição.
  List<SeriePrescrita> get linhas => [
    for (var n = 1; n <= series; n++)
      SeriePrescrita(numero: n, repeticoes: repeticoes),
  ];
}

const padraoAquecimento = PadraoDoBloco(
  series: 2,
  repeticoes: '15',
  descansoSegundos: 45,
);

const padraoAlongamento = PadraoDoBloco(
  series: 2,
  repeticoes: '30s',
  descansoSegundos: 15,
);

const padraoTrabalho = PadraoDoBloco(
  series: prescricaoHipertrofiaSeries,
  repeticoes: prescricaoHipertrofiaReps,
  descansoSegundos: prescricaoHipertrofiaDescanso,
);

PadraoDoBloco padraoDoBloco(String bloco) => switch (bloco) {
  'AQUECIMENTO' => padraoAquecimento,
  'ALONGAMENTO' => padraoAlongamento,
  _ => padraoTrabalho,
};

/// Só o trabalho usa a última prescrição "global" como ponto de partida.
bool usaMemoriaGlobal(String bloco) => bloco != 'AQUECIMENTO' && bloco != 'ALONGAMENTO';

/// Chave da memória por exercício: a do trabalho é a de sempre; aquecimento e
/// alongamento têm a sua, para um não herdar a prescrição do outro.
String chaveMemoriaDoExercicio(int exercicioId, String bloco) =>
    bloco == 'TRABALHO' || bloco == 'AJUSTE' || bloco.isEmpty
    ? 'exercise_prescription_v1_$exercicioId'
    : 'exercise_prescription_v1_${exercicioId}_$bloco';

/// "Adicionando ao aquecimento" / "…ao trabalho" / "…ao alongamento".
String destinoDoAdicionar(String bloco) => switch (bloco) {
  'AQUECIMENTO' => 'Adicionando ao aquecimento',
  'ALONGAMENTO' => 'Adicionando ao alongamento',
  _ => 'Adicionando ao treino',
};
