/// Séries de trabalho de um grupo muscular na semana (valor cru do backend).
class VolumeGrupo {
  const VolumeGrupo({
    required this.grupo,
    required this.series,
    this.exercicios = 0,
    this.dias = const [],
  });

  final String grupo;
  final int series;
  final int exercicios;
  final List<int> dias;

  factory VolumeGrupo.fromJson(Map<String, dynamic> json) => VolumeGrupo(
    grupo: json['grupo'] as String? ?? '',
    series: (json['series'] as num?)?.toInt() ?? 0,
    exercicios: (json['exercicios'] as num?)?.toInt() ?? 0,
    dias: (json['dias'] as List? ?? const [])
        .map((dia) => (dia as num).toInt())
        .toList(growable: false),
  );
}

/// Volume semanal da ficha ou do modelo. Só informa: nada bloqueia nem alerta.
class FichaVolume {
  const FichaVolume({
    this.totalSeries = 0,
    this.grupos = const [],
    this.seriesSemGrupo = 0,
    this.exerciciosSemGrupo = 0,
  });

  static const vazio = FichaVolume();

  final int totalSeries;
  final List<VolumeGrupo> grupos;
  final int seriesSemGrupo;
  final int exerciciosSemGrupo;

  bool get semSeries => totalSeries <= 0;

  factory FichaVolume.fromJson(Object? raw) {
    if (raw is! Map) return vazio;
    final json = Map<String, dynamic>.from(raw);
    return FichaVolume(
      totalSeries: (json['totalSeries'] as num?)?.toInt() ?? 0,
      grupos: (json['grupos'] as List? ?? const [])
          .whereType<Map>()
          .map((g) => VolumeGrupo.fromJson(Map<String, dynamic>.from(g)))
          .toList(growable: false),
      seriesSemGrupo: (json['seriesSemGrupo'] as num?)?.toInt() ?? 0,
      exerciciosSemGrupo: (json['exerciciosSemGrupo'] as num?)?.toInt() ?? 0,
    );
  }
}
