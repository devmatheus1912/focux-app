class SeriePrescrita {
  const SeriePrescrita({
    required this.numero,
    required this.repeticoes,
    this.cargaKg,
    this.papel = 'VALIDA',
  });

  final int numero;
  final String repeticoes;
  final double? cargaKg;
  final String papel;

  bool get aquecimento => papel == 'AQUECIMENTO';

  SeriePrescrita copyWith({
    String? repeticoes,
    double? cargaKg,
    String? papel,
    bool limparCarga = false,
  }) => SeriePrescrita(
    numero: numero,
    repeticoes: repeticoes ?? this.repeticoes,
    cargaKg: limparCarga ? null : (cargaKg ?? this.cargaKg),
    papel: papel ?? this.papel,
  );

  factory SeriePrescrita.fromJson(Map<String, dynamic> json) => SeriePrescrita(
    numero: (json['numero'] as num?)?.toInt() ?? 1,
    repeticoes: json['repeticoes'] as String? ?? '8-12',
    cargaKg: (json['cargaKg'] as num?)?.toDouble(),
    papel: (json['papel'] as String? ?? 'VALIDA').toUpperCase(),
  );

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'repeticoes': repeticoes,
    if (cargaKg != null) 'cargaKg': cargaKg,
    'papel': papel,
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
  );
}

String resumoSeries(List<SeriePrescrita> series, {int descansoSegundos = 75}) {
  if (series.isEmpty) return '0 × $prescricaoHipertrofiaReps · ${descansoSegundos}s';
  final aquecimento = series.where((s) => s.aquecimento).length;
  final validas = series.where((s) => !s.aquecimento).toList();
  final reps = validas.isEmpty ? series.first.repeticoes : validas.first.repeticoes;
  final miolo = validas.isEmpty
      ? '${series.length} × $reps'
      : '${validas.length} × $reps';
  final prefixo = aquecimento > 0 ? '$aquecimento aquecimento · ' : '';
  return '$prefixo$miolo · ${descansoSegundos}s';
}
