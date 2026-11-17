import 'grupos_de_serie.dart';
class SeriePrescrita {
  const SeriePrescrita({
    required this.numero,
    required this.repeticoes,
    this.cargaKg,
    this.papel = 'VALIDA',
    this.descansoSegundos,
    this.tecnica,
  });

  final int numero;
  final String repeticoes;
  final double? cargaKg;
  final String papel;

  /// Descanso depois desta série; nulo = o do exercício.
  final int? descansoSegundos;

  /// Técnica que vale nesta série (DROPSET, PICO…), já resolvida pelo
  /// backend (PlanoDaSerie); nula = nenhuma. Só válida tem.
  final String? tecnica;

  bool get aquecimento => papel == 'AQUECIMENTO';

  SeriePrescrita copyWith({
    String? repeticoes,
    double? cargaKg,
    String? papel,
    bool limparCarga = false,
    String? tecnica,
    bool limparTecnica = false,
  }) => SeriePrescrita(
    numero: numero,
    repeticoes: repeticoes ?? this.repeticoes,
    cargaKg: limparCarga ? null : (cargaKg ?? this.cargaKg),
    papel: papel ?? this.papel,
    descansoSegundos: descansoSegundos,
    tecnica: limparTecnica ? null : (tecnica ?? this.tecnica),
  );

  factory SeriePrescrita.fromJson(Map<String, dynamic> json) => SeriePrescrita(
    numero: (json['numero'] as num?)?.toInt() ?? 1,
    repeticoes: json['repeticoes'] as String? ?? '8-12',
    cargaKg: (json['cargaKg'] as num?)?.toDouble(),
    papel: (json['papel'] as String? ?? 'VALIDA').toUpperCase(),
    descansoSegundos: (json['descansoSegundos'] as num?)?.toInt(),
    tecnica: json['tecnica'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'repeticoes': repeticoes,
    if (cargaKg != null) 'cargaKg': cargaKg,
    'papel': papel,
    if (descansoSegundos != null) 'descansoSegundos': descansoSegundos,
    if (tecnica != null) 'tecnica': tecnica,
  };
}

const prescricaoHipertrofiaSeries = 4;
const prescricaoHipertrofiaReps = '8-12';
const prescricaoHipertrofiaDescanso = 75;

List<SeriePrescrita> seriesIniciais({
  List<SeriePrescrita>? desteExercicio,
  List<SeriePrescrita>? ultimaGlobal,
}) {
  final escolhida = desteExercicio ?? ultimaGlobal;
  if (escolhida != null && escolhida.isNotEmpty) {
    return [
      for (var i = 0; i < escolhida.length; i++)
        SeriePrescrita(
          numero: i + 1,
          repeticoes: escolhida[i].repeticoes,
          cargaKg: escolhida[i].cargaKg,
          papel: escolhida[i].papel,
        ),
    ];
  }
  return [
    for (var n = 1; n <= prescricaoHipertrofiaSeries; n++)
      const SeriePrescrita(numero: 1, repeticoes: prescricaoHipertrofiaReps)
          .copyWith(repeticoes: prescricaoHipertrofiaReps)
          .comNumero(n),
  ];
}

extension SeriePrescritaNumero on SeriePrescrita {
  SeriePrescrita comNumero(int numero) => SeriePrescrita(
    numero: numero,
    repeticoes: repeticoes,
    cargaKg: cargaKg,
    papel: papel,
    descansoSegundos: descansoSegundos,
    tecnica: tecnica,
  );
}

String resumoSeries(List<SeriePrescrita> series, {int descansoSegundos = 75}) {
  if (series.isEmpty) return '0 × $prescricaoHipertrofiaReps · $descansoSegundos s';
  // Com aquecimento, ajuste ou back-off, o resumo diz cada grupo.
  final grupos = resumoDosGrupos(series, descansoExercicio: descansoSegundos);
  if (grupos != null) return grupos;
  return '${series.length} × ${series.first.repeticoes} · $descansoSegundos s';
}
