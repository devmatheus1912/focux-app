import '../data/enums.dart';

class ExerciciosUiFilter {
  final String query;
  final Modalidade? modalidade;
  final GrupoMuscular? grupo;
  final Equipamento? equipamento;
  final Dificuldade? dificuldade;
  final bool favoritos;
  final bool comVideo;
  final bool semVideo;

  const ExerciciosUiFilter({
    this.query = '',
    this.modalidade,
    this.grupo,
    this.equipamento,
    this.dificuldade,
    this.favoritos = false,
    this.comVideo = false,
    this.semVideo = false,
  });

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasFacet =>
      modalidade != null ||
      grupo != null ||
      equipamento != null ||
      dificuldade != null ||
      favoritos ||
      comVideo ||
      semVideo;

  bool get hasActive => hasQuery || hasFacet;

  ExerciciosUiFilter copyWith({
    String? query,
    Modalidade? modalidade,
    GrupoMuscular? grupo,
    Equipamento? equipamento,
    Dificuldade? dificuldade,
    bool? favoritos,
    bool? comVideo,
    bool? semVideo,
    bool clearModalidade = false,
    bool clearGrupo = false,
    bool clearEquipamento = false,
    bool clearDificuldade = false,
  }) {
    return ExerciciosUiFilter(
      query: query ?? this.query,
      modalidade: clearModalidade ? null : (modalidade ?? this.modalidade),
      grupo: clearGrupo ? null : (grupo ?? this.grupo),
      equipamento: clearEquipamento ? null : (equipamento ?? this.equipamento),
      dificuldade: clearDificuldade ? null : (dificuldade ?? this.dificuldade),
      favoritos: favoritos ?? this.favoritos,
      comVideo: comVideo ?? this.comVideo,
      semVideo: semVideo ?? this.semVideo,
    );
  }
}
