/// Técnica de intensidade: o que acontece dentro da série. A pirâmide não é
/// técnica: é a [Progressao] das válidas (SPEC-metodos-por-serie).
enum Tecnica { normal, dropset, restpause, pico, excentrica, isometria, parciais }

/// Como reps e carga mudam de uma válida para a outra.
enum Progressao { fixa, piramideCrescente, piramideDecrescente }

/// Onde a técnica vale entre as válidas.
enum EmQuaisSeries { ultima, todas, escolher }

/// "PIRAMIDE" é legado do tipo_serie: vira progressão, não técnica.
Tecnica tecnicaDe(String? bruto) => switch ((bruto ?? '').toUpperCase()) {
  'DROPSET' => Tecnica.dropset,
  'RESTPAUSE' => Tecnica.restpause,
  'PICO' => Tecnica.pico,
  'EXCENTRICA' => Tecnica.excentrica,
  'ISOMETRIA' => Tecnica.isometria,
  'PARCIAIS' => Tecnica.parciais,
  _ => Tecnica.normal,
};

String tecnicaParaApi(Tecnica t) => switch (t) {
  Tecnica.normal => 'NORMAL',
  Tecnica.dropset => 'DROPSET',
  Tecnica.restpause => 'RESTPAUSE',
  Tecnica.pico => 'PICO',
  Tecnica.excentrica => 'EXCENTRICA',
  Tecnica.isometria => 'ISOMETRIA',
  Tecnica.parciais => 'PARCIAIS',
};

Progressao progressaoDe(String? bruto, {String? tipoSerie}) => switch ((bruto ?? '').toUpperCase()) {
  'PIRAMIDE_CRESCENTE' => Progressao.piramideCrescente,
  'PIRAMIDE_DECRESCENTE' => Progressao.piramideDecrescente,
  'FIXA' => Progressao.fixa,
  // Resposta antiga: PIRAMIDE no tipo_serie era sempre crescente.
  _ => (tipoSerie ?? '').toUpperCase() == 'PIRAMIDE' ? Progressao.piramideCrescente : Progressao.fixa,
};

String progressaoParaApi(Progressao p) => switch (p) {
  Progressao.fixa => 'FIXA',
  Progressao.piramideCrescente => 'PIRAMIDE_CRESCENTE',
  Progressao.piramideDecrescente => 'PIRAMIDE_DECRESCENTE',
};

/// `tipoSerie` que a API e o app das lojas entendem: a técnica, senão PIRAMIDE
/// (para o app antigo ainda mostrar "Pirâmide"), senão NORMAL.
String tipoSerieParaApi(Tecnica t, Progressao p) => t != Tecnica.normal
    ? tecnicaParaApi(t)
    : p == Progressao.fixa
    ? 'NORMAL'
    : 'PIRAMIDE';

/// Técnicas de tempo usam segundos; parciais usam repetições.
bool tecnicaDeTempo(Tecnica t) =>
    t == Tecnica.pico || t == Tecnica.excentrica || t == Tecnica.isometria;

/// Onde a técnica vale quando o personal não escolhe: drop, rest-pause e
/// parciais na última; as de tempo em todas.
EmQuaisSeries emQuaisSeriesPadrao(Tecnica t) =>
    tecnicaDeTempo(t) ? EmQuaisSeries.todas : EmQuaisSeries.ultima;

/// Como o exercício é feito: progressão, técnica com os parâmetros e o combinado.
class MetodoExercicio {
  const MetodoExercicio({
    this.tecnica = Tecnica.normal,
    this.progressao = Progressao.fixa,
    this.quedas,
    this.reducaoPct,
    this.pausaS,
    this.miniSeries,
    this.segundos,
    this.parciais,
    this.grupo,
    this.grupoRotulo,
  });

  static const normal = MetodoExercicio();

  final Tecnica tecnica;
  final Progressao progressao;
  final int? quedas;
  final int? reducaoPct;
  final int? pausaS;
  final int? miniSeries;

  /// Pico de contração, excêntrica lenta e isometria.
  final int? segundos;

  /// Repetições parciais no fim da série.
  final int? parciais;

  /// Id do combinado no treino (bi-set, tri-set, circuito, superset); nulo = sozinho.
  final int? grupo;

  /// BISET, TRISET, CIRCUITO ou SUPERSET.
  final String? grupoRotulo;

  bool get combinado => grupo != null;
  bool get piramide => progressao != Progressao.fixa;

  /// Lê o "metodo" da resposta; respostas antigas só tinham tipoSerie e grupoSuperset.
  factory MetodoExercicio.fromJson(Map<String, dynamic>? json, {String? tipoSerie, int? grupoSuperset}) {
    if (json == null) {
      final antigoSuperset = (tipoSerie ?? '').toUpperCase() == 'SUPERSET';
      return MetodoExercicio(
        tecnica: antigoSuperset ? Tecnica.normal : tecnicaDe(tipoSerie),
        progressao: progressaoDe(null, tipoSerie: tipoSerie),
        grupo: grupoSuperset,
        grupoRotulo: antigoSuperset && grupoSuperset != null ? 'SUPERSET' : null,
      );
    }
    int? n(String k) => (json[k] as num?)?.toInt();
    final tecnicaBruta = json['tecnica'] as String?;
    return MetodoExercicio(
      tecnica: tecnicaDe(tecnicaBruta),
      progressao: progressaoDe(json['progressao'] as String?, tipoSerie: tecnicaBruta),
      quedas: n('quedas'),
      reducaoPct: n('reducaoPct'),
      pausaS: n('pausaS'),
      miniSeries: n('miniSeries'),
      segundos: n('segundos'),
      parciais: n('parciais'),
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
  Tecnica.normal => 'Nenhuma',
  Tecnica.dropset => 'Drop-set',
  Tecnica.restpause => 'Rest-pause',
  Tecnica.pico => 'Pico de contração',
  Tecnica.excentrica => 'Excêntrica lenta',
  Tecnica.isometria => 'Isometria',
  Tecnica.parciais => 'Parciais',
};

/// Rótulo curto da progressão ("Pirâmide ↑").
String rotuloDaProgressao(Progressao p) => switch (p) {
  Progressao.fixa => 'Fixa',
  Progressao.piramideCrescente => 'Pirâmide ↑',
  Progressao.piramideDecrescente => 'Pirâmide ↓',
};

/// A técnica com o parâmetro, curta: "Drop-set", "Pico 2 s", "Excêntrica 4 s".
String rotuloCurtoDaTecnica(Tecnica t, MetodoExercicio m) => switch (t) {
  Tecnica.pico => 'Pico ${m.segundos ?? 2} s',
  Tecnica.excentrica => 'Excêntrica ${m.segundos ?? 4} s',
  Tecnica.isometria => 'Isometria ${m.segundos ?? 5} s',
  _ => rotuloDaTecnica(t),
};

/// O que a folha da prescrição guarda para o método escolhido.
class ParametrosDoMetodo {
  const ParametrosDoMetodo({
    this.quedas = 2,
    this.reducaoPct = 20,
    this.pausaS = 15,
    this.miniSeries = 2,
    this.segundos = 2,
    this.parciais = 8,
    this.progressao = Progressao.fixa,
    this.emQuais,
    this.escolhidas = const {},
  });

  /// Lê o que está gravado: o sentido da pirâmide e as séries marcadas voltam
  /// como foram salvos ([marcadas] = números das válidas com a técnica, em ordem
  /// entre as válidas: 1 = primeira válida).
  factory ParametrosDoMetodo.de(MetodoExercicio m, {List<int> marcadas = const [], int validas = 0}) {
    EmQuaisSeries? emQuais;
    if (m.tecnica != Tecnica.normal && validas > 0 && marcadas.isNotEmpty) {
      emQuais = marcadas.length == validas
          ? EmQuaisSeries.todas
          : marcadas.length == 1 && marcadas.single == validas
          ? EmQuaisSeries.ultima
          : EmQuaisSeries.escolher;
    }
    return ParametrosDoMetodo(
      quedas: m.quedas ?? 2,
      reducaoPct: m.reducaoPct ?? 20,
      pausaS: m.pausaS ?? 15,
      miniSeries: m.miniSeries ?? 2,
      segundos: m.segundos ?? (m.tecnica == Tecnica.excentrica ? 4 : m.tecnica == Tecnica.isometria ? 5 : 2),
      parciais: m.parciais ?? 8,
      progressao: m.progressao,
      emQuais: emQuais,
      escolhidas: emQuais == EmQuaisSeries.escolher ? marcadas.toSet() : const {},
    );
  }

  final int quedas;
  final int reducaoPct;
  final int pausaS;
  final int miniSeries;
  final int segundos;
  final int parciais;
  final Progressao progressao;

  /// Nulo = o padrão da técnica ([emQuaisSeriesPadrao]).
  final EmQuaisSeries? emQuais;

  /// Válidas escolhidas (1 = primeira válida), quando [emQuais] é escolher.
  final Set<int> escolhidas;

  /// Crescente: carga sobe e reps descem a cada série.
  bool get piramideCrescente => progressao != Progressao.piramideDecrescente;

  EmQuaisSeries emQuaisPara(Tecnica t) => emQuais ?? emQuaisSeriesPadrao(t);

  /// Em quais válidas (1..[validas]) a técnica [t] vale.
  Set<int> validasComTecnica(Tecnica t, int validas) {
    if (t == Tecnica.normal || validas < 1) return const {};
    return switch (emQuaisPara(t)) {
      EmQuaisSeries.todas => {for (var i = 1; i <= validas; i++) i},
      EmQuaisSeries.ultima => {validas},
      EmQuaisSeries.escolher => {
        for (final i in escolhidas)
          if (i >= 1 && i <= validas) i,
      },
    };
  }

  ParametrosDoMetodo copyWith({
    int? quedas,
    int? reducaoPct,
    int? pausaS,
    int? miniSeries,
    int? segundos,
    int? parciais,
    Progressao? progressao,
    EmQuaisSeries? emQuais,
    bool limparEmQuais = false,
    Set<int>? escolhidas,
  }) => ParametrosDoMetodo(
    quedas: quedas ?? this.quedas,
    reducaoPct: reducaoPct ?? this.reducaoPct,
    pausaS: pausaS ?? this.pausaS,
    miniSeries: miniSeries ?? this.miniSeries,
    segundos: segundos ?? this.segundos,
    parciais: parciais ?? this.parciais,
    progressao: progressao ?? this.progressao,
    emQuais: limparEmQuais ? null : (emQuais ?? this.emQuais),
    escolhidas: escolhidas ?? this.escolhidas,
  );
}

/// Metas por série da pirâmide. Crescente: reps descem 2 por série a partir do
/// topo da faixa ("8-12" → 12, 10, 8, 6) e a carga sobe 10% (arredondada a 0,5 kg);
/// decrescente: o contrário. Reps nunca abaixo de 4. [repsBase] é sempre a faixa
/// que o personal escreveu (nunca a 1ª linha já gerada: na decrescente ela é a
/// menor, e recalcular a partir dela encolhia a pirâmide a cada salvar).
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

/// A faixa e a carga de partida de uma pirâmide já gerada: o topo de reps
/// (a maior meta) e a carga da série de mais reps. Assim reabrir e salvar
/// devolve a mesma pirâmide, nos dois sentidos.
({String repsBase, double? carga}) baseDaPiramide(List<({String reps, double? carga})> linhas) {
  if (linhas.isEmpty) return (repsBase: '12', carga: null);
  int reps(String r) => int.tryParse(RegExp(r'\d+').firstMatch(r)?.group(0) ?? '') ?? 0;
  final topo = linhas.reduce((a, b) => reps(b.reps) > reps(a.reps) ? b : a);
  return (repsBase: topo.reps, carga: topo.carga);
}
