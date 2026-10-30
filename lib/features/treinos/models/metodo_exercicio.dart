/// Técnica da série (o que muda dentro do exercício).
enum Tecnica { normal, piramide, dropset, restpause }

Tecnica tecnicaDe(String? bruto) => switch ((bruto ?? '').toUpperCase()) {
  'PIRAMIDE' => Tecnica.piramide,
  'DROPSET' => Tecnica.dropset,
  'RESTPAUSE' => Tecnica.restpause,
  _ => Tecnica.normal,
};

String tecnicaParaApi(Tecnica t) => switch (t) {
  Tecnica.normal => 'NORMAL',
  Tecnica.piramide => 'PIRAMIDE',
  Tecnica.dropset => 'DROPSET',
  Tecnica.restpause => 'RESTPAUSE',
};

/// Como o exercício é feito: técnica com os parâmetros e o combinado de que faz parte.
class MetodoExercicio {
  const MetodoExercicio({
    this.tecnica = Tecnica.normal,
    this.quedas,
    this.reducaoPct,
    this.pausaS,
    this.miniSeries,
    this.grupo,
    this.grupoRotulo,
  });

  static const normal = MetodoExercicio();

  final Tecnica tecnica;
  final int? quedas;
  final int? reducaoPct;
  final int? pausaS;
  final int? miniSeries;

  /// Id do combinado no treino (bi-set, tri-set, circuito, superset); nulo = sozinho.
  final int? grupo;

  /// BISET, TRISET, CIRCUITO ou SUPERSET.
  final String? grupoRotulo;

  bool get combinado => grupo != null;

  /// Lê o "metodo" da resposta; respostas antigas só tinham tipoSerie e grupoSuperset.
  factory MetodoExercicio.fromJson(Map<String, dynamic>? json, {String? tipoSerie, int? grupoSuperset}) {
    if (json == null) {
      final antigoSuperset = (tipoSerie ?? '').toUpperCase() == 'SUPERSET';
      return MetodoExercicio(
        tecnica: antigoSuperset ? Tecnica.normal : tecnicaDe(tipoSerie),
        grupo: grupoSuperset,
        grupoRotulo: antigoSuperset && grupoSuperset != null ? 'SUPERSET' : null,
      );
    }
    int? n(String k) => (json[k] as num?)?.toInt();
    return MetodoExercicio(
      tecnica: tecnicaDe(json['tecnica'] as String?),
      quedas: n('quedas'),
      reducaoPct: n('reducaoPct'),
      pausaS: n('pausaS'),
      miniSeries: n('miniSeries'),
      grupo: n('grupo'),
      grupoRotulo: json['grupoRotulo'] as String?,
    );
  }
}

/// Nome do combinado como o personal vê: pelo rótulo ou pelo tamanho.
String rotuloDoCombinado(String? rotulo, int tamanho) => switch (rotulo) {
  'SUPERSET' => 'Superset',
  'BISET' => 'Bi-set',
  'TRISET' => 'Tri-set',
  'CIRCUITO' => 'Circuito',
  _ => tamanho == 2 ? 'Bi-set' : tamanho == 3 ? 'Tri-set' : 'Circuito',
};

/// Rótulo da técnica para chips e cartões.
String rotuloDaTecnica(Tecnica t) => switch (t) {
  Tecnica.normal => 'Normal',
  Tecnica.piramide => 'Pirâmide',
  Tecnica.dropset => 'Drop-set',
  Tecnica.restpause => 'Rest-pause',
};

/// O que a folha da prescrição guarda para a técnica escolhida.
class ParametrosDoMetodo {
  const ParametrosDoMetodo({
    this.quedas = 2,
    this.reducaoPct = 20,
    this.pausaS = 15,
    this.miniSeries = 2,
    this.piramideCrescente = true,
  });

  factory ParametrosDoMetodo.de(MetodoExercicio m) => ParametrosDoMetodo(
    quedas: m.quedas ?? 2,
    reducaoPct: m.reducaoPct ?? 20,
    pausaS: m.pausaS ?? 15,
    miniSeries: m.miniSeries ?? 2,
  );

  final int quedas;
  final int reducaoPct;
  final int pausaS;
  final int miniSeries;

  /// Crescente: carga sobe e reps descem a cada série.
  final bool piramideCrescente;

  ParametrosDoMetodo copyWith({
    int? quedas,
    int? reducaoPct,
    int? pausaS,
    int? miniSeries,
    bool? piramideCrescente,
  }) => ParametrosDoMetodo(
    quedas: quedas ?? this.quedas,
    reducaoPct: reducaoPct ?? this.reducaoPct,
    pausaS: pausaS ?? this.pausaS,
    miniSeries: miniSeries ?? this.miniSeries,
    piramideCrescente: piramideCrescente ?? this.piramideCrescente,
  );
}

/// Metas por série da pirâmide. Crescente: reps descem 2 por série a partir do
/// topo da faixa ("8-12" → 12, 10, 8, 6) e a carga sobe 10% (arredondada a 0,5 kg);
/// decrescente: o contrário. Reps nunca abaixo de 4.
List<({String reps, double? carga})> linhasDaPiramide({
  required int series,
  required bool crescente,
  required String repsBase,
  double? carga,
}) {
  final numeros = RegExp(r'\d+').allMatches(repsBase).map((m) => int.parse(m.group(0)!)).toList();
  final topo = numeros.isEmpty ? 12 : numeros.reduce((a, b) => a > b ? a : b);
  double? cargaDa(int passo) =>
      carga == null || carga <= 0 ? null : ((carga * (1 + 0.1 * passo)) * 2).round() / 2;
  final subindo = [
    for (var i = 0; i < series; i++) (reps: '${(topo - 2 * i).clamp(4, 99)}', carga: cargaDa(i)),
  ];
  return crescente ? subindo : subindo.reversed.toList();
}
