/// Exercício mais treinado nas últimas 8 semanas e a curva do 1RM estimado
/// (só semanas com o exercício). Null em backend antigo ou sem séries com carga.
class AlunoDestaqueExercicio {
  final String nome;
  final List<double> serieSemanal;
  final double inicialKg;
  final double atualKg;
  final double deltaPercent;
  final int semanas;

  const AlunoDestaqueExercicio({
    required this.nome,
    required this.serieSemanal,
    required this.inicialKg,
    required this.atualKg,
    required this.deltaPercent,
    required this.semanas,
  });

  /// A curva só aparece a partir da 3ª semana com o exercício.
  static const minPontosCurva = 3;

  bool get temCurva => serieSemanal.length >= minPontosCurva;

  static AlunoDestaqueExercicio? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final nome = raw['nome'];
    final serie = raw['serieSemanal'];
    final inicial = raw['inicialKg'];
    final atual = raw['atualKg'];
    if (nome is! String || nome.trim().isEmpty) return null;
    if (serie is! List || inicial is! num || atual is! num) return null;
    final pontos = serie.whereType<num>().map((v) => v.toDouble()).toList();
    if (pontos.isEmpty) return null;
    return AlunoDestaqueExercicio(
      nome: nome.trim(),
      serieSemanal: List.unmodifiable(pontos),
      inicialKg: inicial.toDouble(),
      atualKg: atual.toDouble(),
      deltaPercent: (raw['deltaPercent'] as num?)?.toDouble() ?? 0,
      semanas: (raw['semanas'] as num?)?.toInt() ?? pontos.length,
    );
  }
}
