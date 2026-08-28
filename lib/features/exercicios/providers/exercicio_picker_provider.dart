import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';
import '../data/exercicio_page.dart';
import 'exercicios_provider.dart';

/// Query paginada para picker de treino — espelha GET /api/exercicios/picker.
class ExercicioPickerQuery {
  final String? busca;
  final PadraoMovimento? padraoMovimento;
  final GrupoMuscular? grupoMuscularPrimario;
  final bool somenteFavoritos;
  final bool somenteComVideo;
  final int page;

  const ExercicioPickerQuery({
    this.busca,
    this.padraoMovimento,
    this.grupoMuscularPrimario,
    this.somenteFavoritos = false,
    this.somenteComVideo = false,
    this.page = 0,
  });

  ExercicioPickerQuery nextPage() => ExercicioPickerQuery(
    busca: busca,
    padraoMovimento: padraoMovimento,
    grupoMuscularPrimario: grupoMuscularPrimario,
    somenteFavoritos: somenteFavoritos,
    somenteComVideo: somenteComVideo,
    page: page + 1,
  );

  @override
  bool operator ==(Object other) =>
      other is ExercicioPickerQuery &&
      other.busca == busca &&
      other.padraoMovimento == padraoMovimento &&
      other.grupoMuscularPrimario == grupoMuscularPrimario &&
      other.somenteFavoritos == somenteFavoritos &&
      other.somenteComVideo == somenteComVideo &&
      other.page == page;

  @override
  int get hashCode => Object.hash(
    busca,
    padraoMovimento,
    grupoMuscularPrimario,
    somenteFavoritos,
    somenteComVideo,
    page,
  );
}

final exercicioPickerStatsProvider = FutureProvider<ExercicioPickerStats>((
  ref,
) async {
  return ref.read(exercicioRepositoryProvider).buscarPickerStats();
});

final exercicioPickerPageProvider =
    FutureProvider.family<ExercicioPickerPage, ExercicioPickerQuery>((
      ref,
      query,
    ) async {
      return ref.read(exercicioRepositoryProvider).listarPickerPagina(
        busca: query.busca,
        padraoMovimento: query.padraoMovimento?.name,
        grupoMuscularPrimario: query.grupoMuscularPrimario?.name,
        hasVideo: query.somenteComVideo ? true : null,
        favoritos: query.somenteFavoritos ? true : null,
        page: query.page,
      );
    });

/// Query paginada para lista admin de exercícios — GET /api/exercicios/v2.
class ExercicioListQuery {
  final String? busca;
  final Modalidade? modalidade;
  final GrupoMuscular? grupo;
  final Equipamento? equipamento;
  final Dificuldade? dificuldade;
  final bool favoritos;
  final bool comVideo;
  final bool semVideo;
  final int page;

  const ExercicioListQuery({
    this.busca,
    this.modalidade,
    this.grupo,
    this.equipamento,
    this.dificuldade,
    this.favoritos = false,
    this.comVideo = false,
    this.semVideo = false,
    this.page = 0,
  });

  ExercicioListQuery nextPage() => ExercicioListQuery(
    busca: busca,
    modalidade: modalidade,
    grupo: grupo,
    equipamento: equipamento,
    dificuldade: dificuldade,
    favoritos: favoritos,
    comVideo: comVideo,
    semVideo: semVideo,
    page: page + 1,
  );

  @override
  bool operator ==(Object other) =>
      other is ExercicioListQuery &&
      other.busca == busca &&
      other.modalidade == modalidade &&
      other.grupo == grupo &&
      other.equipamento == equipamento &&
      other.dificuldade == dificuldade &&
      other.favoritos == favoritos &&
      other.comVideo == comVideo &&
      other.semVideo == semVideo &&
      other.page == page;

  @override
  int get hashCode => Object.hash(
    busca,
    modalidade,
    grupo,
    equipamento,
    dificuldade,
    favoritos,
    comVideo,
    semVideo,
    page,
  );
}

final exercicioListPageProvider =
    FutureProvider.family<ExercicioPage, ExercicioListQuery>((ref, query) async {
      return ref.read(exercicioRepositoryProvider).listarPagina(
        busca: query.busca,
        modalidade: query.modalidade?.name,
        grupoMuscularPrimario: query.grupo?.name,
        equipamento: query.equipamento?.name,
        dificuldade: query.dificuldade?.name,
        favoritos: query.favoritos ? true : null,
        hasVideo: query.comVideo ? true : null,
        page: query.page,
      );
    });
