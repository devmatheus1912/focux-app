import '../utils/checkin_json.dart';

/// `GET /api/checkin/treinos/{treinoId}/previa`: prescrição sem abrir sessão.
class TreinoPrevia {
  const TreinoPrevia({
    required this.treinoId,
    required this.treinoNome,
    required this.exercicios,
    this.dataFim,
  });

  final int treinoId;
  final String treinoNome;

  /// Prazo soft da atribuição (ISO date).
  final String? dataFim;
  final List<TreinoPreviaExercicio> exercicios;

  factory TreinoPrevia.fromJson(Map<String, dynamic> j) => TreinoPrevia(
    treinoId: checkinJsonIntOr(j['treinoId']),
    treinoNome: checkinJsonStringOr(j['treinoNome'], 'Treino'),
    dataFim: checkinJsonString(j['dataFim']),
    exercicios: checkinJsonMapList(
      j['exercicios'],
    ).map(TreinoPreviaExercicio.fromJson).toList(growable: false),
  );
}

class TreinoPreviaExercicio {
  const TreinoPreviaExercicio({
    required this.treinoExercicioId,
    required this.exercicioNome,
    this.series,
    this.repeticoes,
    this.cargaKg,
    this.descansoSegundos,
    this.observacoes,
    this.thumbnailUrl,
    this.gifUrl,
    this.temVideo = false,
  });

  final int treinoExercicioId;
  final String exercicioNome;
  final int? series;
  final String? repeticoes;
  final double? cargaKg;
  final int? descansoSegundos;
  final String? observacoes;
  final String? thumbnailUrl;
  final String? gifUrl;
  final bool temVideo;

  /// Miniatura estática antes do GIF (lista leve).
  String? get imagemUrl => thumbnailUrl ?? gifUrl;

  factory TreinoPreviaExercicio.fromJson(Map<String, dynamic> j) =>
      TreinoPreviaExercicio(
        treinoExercicioId: checkinJsonIntOr(j['treinoExercicioId']),
        exercicioNome: checkinJsonStringOr(j['exercicioNome'], 'Exercício'),
        series: checkinJsonInt(j['series']),
        repeticoes: checkinJsonString(j['repeticoes']),
        cargaKg: checkinJsonDouble(j['cargaKg']),
        descansoSegundos: checkinJsonInt(j['descansoSegundos']),
        observacoes: checkinJsonString(j['observacoes']),
        thumbnailUrl: checkinJsonString(j['thumbnailUrl']),
        gifUrl: checkinJsonString(j['gifUrl']),
        temVideo: checkinJsonBool(j['temVideo']),
      );
}
