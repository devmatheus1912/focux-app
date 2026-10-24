import '../models/ficha_volume.dart';

/// Os 20 grupos do backend viram 14 grupos de leitura. A ordem do enum é a
/// ordem de desempate quando duas linhas têm as mesmas séries.
enum GrupoDeLeitura {
  peito,
  costas,
  ombros,
  biceps,
  triceps,
  antebraco,
  quadriceps,
  posteriorCoxa,
  gluteo,
  quadril,
  panturrilha,
  abdomen,
  lombar,
  corpoTodo,
  outros,
}

const _grupoPorValor = {
  'PEITO': GrupoDeLeitura.peito,
  'COSTAS_LATISSIMO': GrupoDeLeitura.costas,
  'COSTAS_RETANGULARES': GrupoDeLeitura.costas,
  'TRAPEZIO': GrupoDeLeitura.costas,
  'OMBRO_ANTERIOR': GrupoDeLeitura.ombros,
  'OMBRO_LATERAL': GrupoDeLeitura.ombros,
  'OMBRO_POSTERIOR': GrupoDeLeitura.ombros,
  'BICEPS': GrupoDeLeitura.biceps,
  'TRICEPS': GrupoDeLeitura.triceps,
  'ANTEBRACO': GrupoDeLeitura.antebraco,
  'QUADRICEPS': GrupoDeLeitura.quadriceps,
  'POSTERIOR_COXA': GrupoDeLeitura.posteriorCoxa,
  'GLUTEO': GrupoDeLeitura.gluteo,
  'ADUTOR': GrupoDeLeitura.quadril,
  'ABDUTOR': GrupoDeLeitura.quadril,
  'PANTURRILHA': GrupoDeLeitura.panturrilha,
  'ABDOMEN': GrupoDeLeitura.abdomen,
  'OBLIQUO': GrupoDeLeitura.abdomen,
  'LOMBAR': GrupoDeLeitura.lombar,
  'FULL_BODY': GrupoDeLeitura.corpoTodo,
};

/// Valor novo que o app ainda não conhece cai em "Outros", para a conta fechar.
GrupoDeLeitura grupoDeLeitura(String valorDoBackend) =>
    _grupoPorValor[valorDoBackend] ?? GrupoDeLeitura.outros;

class LinhaDeVolume {
  const LinhaDeVolume({
    required this.grupo,
    required this.series,
    required this.exercicios,
    required this.dias,
  });

  final GrupoDeLeitura grupo;
  final int series;
  final int exercicios;
  final List<int> dias;
}

/// Junta os grupos crus em grupos de leitura, do que tem mais séries para o que
/// tem menos (empate pela ordem de [GrupoDeLeitura]).
List<LinhaDeVolume> linhasDeVolume(FichaVolume volume) {
  final series = <GrupoDeLeitura, int>{};
  final exercicios = <GrupoDeLeitura, int>{};
  final dias = <GrupoDeLeitura, Set<int>>{};
  for (final grupo in volume.grupos) {
    final leitura = grupoDeLeitura(grupo.grupo);
    series[leitura] = (series[leitura] ?? 0) + grupo.series;
    exercicios[leitura] = (exercicios[leitura] ?? 0) + grupo.exercicios;
    dias.putIfAbsent(leitura, () => {}).addAll(grupo.dias);
  }
  final linhas = [
    for (final entrada in series.entries)
      LinhaDeVolume(
        grupo: entrada.key,
        series: entrada.value,
        exercicios: exercicios[entrada.key] ?? 0,
        dias: (dias[entrada.key] ?? {}).toList()..sort(),
      ),
  ];
  linhas.sort((a, b) {
    final porSeries = b.series.compareTo(a.series);
    return porSeries != 0 ? porSeries : a.grupo.index.compareTo(b.grupo.index);
  });
  return linhas;
}

/// Faixa de referência comum para hipertrofia. É só contexto visual: nunca vira
/// alerta, meta ou "ideal".
const faixaReferenciaMin = 10;
const faixaReferenciaMax = 20;

/// Escala da barra: cabe o maior grupo e a faixa de referência inteira.
int escalaDaBarra(List<LinhaDeVolume> linhas) {
  final maior = linhas.fold<int>(0, (m, l) => l.series > m ? l.series : m);
  return maior > faixaReferenciaMax ? maior : faixaReferenciaMax;
}

/// Proporção (0 a 1) de [series] na [escala].
double proporcaoDaBarra(int series, int escala) =>
    escala <= 0 ? 0 : (series / escala).clamp(0.0, 1.0);
