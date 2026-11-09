import '../utils/checkin_json.dart';

/// Resumo BFF da sessão (`GET /checkin/{id}/evolucao-sessao`).
class SessaoEvolucaoDto {
  final int? execucaoId;
  final double? volumeKg;
  final double? volumeAnteriorKg;
  final int seriesFeitas;
  final int seriesPlanejadas;
  final int recordes;
  final String sinal;
  final String sinalLabel;
  final String? destaqueExercicio;
  final double? destaqueDeltaKg;

  const SessaoEvolucaoDto({
    this.execucaoId,
    this.volumeKg,
    this.volumeAnteriorKg,
    required this.seriesFeitas,
    required this.seriesPlanejadas,
    required this.recordes,
    required this.sinal,
    required this.sinalLabel,
    this.destaqueExercicio,
    this.destaqueDeltaKg,
  });

  factory SessaoEvolucaoDto.fromJson(Map<String, dynamic> j) =>
      SessaoEvolucaoDto(
        execucaoId: checkinJsonInt(j['execucaoId']),
        volumeKg: checkinJsonDouble(j['volumeKg']),
        volumeAnteriorKg: checkinJsonDouble(j['volumeAnteriorKg']),
        seriesFeitas: checkinJsonIntOr(j['seriesFeitas']),
        seriesPlanejadas: checkinJsonIntOr(j['seriesPlanejadas']),
        recordes: checkinJsonIntOr(j['recordes']),
        sinal: checkinJsonStringOr(j['sinal'], 'SEM_DADOS'),
        sinalLabel: checkinJsonStringOr(
          j['sinalLabel'],
          'Sem séries registradas',
        ),
        destaqueExercicio: checkinJsonString(j['destaqueExercicio']),
        destaqueDeltaKg: checkinJsonDouble(j['destaqueDeltaKg']),
      );
}
