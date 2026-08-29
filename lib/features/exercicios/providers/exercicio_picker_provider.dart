import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_enum_api.dart';
import '../data/enums.dart';
import '../data/exercicio_page.dart';
import 'exercicios_provider.dart';

/// Query paginada para picker de treino — espelha GET /api/exercicios/picker.
class ExercicioPickerQuery {
  final String? busca;
  final PadraoMovimento? padraoMovimento;
  final GrupoMuscular? grupoMuscularPrimario;
  final Espaco? espaco;
  final Equipamento? equipamento;
  final Set<Equipamento> equipamentosAluno;
  final bool somenteFavoritos;
  final bool somenteComVideo;
  final int page;

  const ExercicioPickerQuery({
    this.busca,
    this.padraoMovimento,
    this.grupoMuscularPrimario,
    this.espaco,
    this.equipamento,
    this.equipamentosAluno = const {},
    this.somenteFavoritos = false,
    this.somenteComVideo = false,
    this.page = 0,
  });

  ExercicioPickerQuery nextPage() => ExercicioPickerQuery(
    busca: busca,
    padraoMovimento: padraoMovimento,
    grupoMuscularPrimario: grupoMuscularPrimario,
    espaco: espaco,
    equipamento: equipamento,
    equipamentosAluno: equipamentosAluno,
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
      other.espaco == espaco &&
      other.equipamento == equipamento &&
      _setEquals(other.equipamentosAluno, equipamentosAluno) &&
      other.somenteFavoritos == somenteFavoritos &&
      other.somenteComVideo == somenteComVideo &&
      other.page == page;

  @override
  int get hashCode => Object.hash(
    busca,
    padraoMovimento,
    grupoMuscularPrimario,
    espaco,
    equipamento,
    _setHash(equipamentosAluno),
    somenteFavoritos,
    somenteComVideo,
    page,
  );
}

bool _setEquals(Set<Equipamento> a, Set<Equipamento> b) {
  if (a.length != b.length) return false;
  for (final item in a) {
    if (!b.contains(item)) return false;
  }
  return true;
}

int _setHash(Set<Equipamento> values) {
  final sorted = values.map((e) => e.name).toList()..sort();
  return Object.hashAll(sorted);
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
        padraoMovimento: enumQueryParam(query.padraoMovimento),
        grupoMuscularPrimario: enumQueryParam(query.grupoMuscularPrimario),
        espaco: enumQueryParam(query.espaco),
        equipamento: enumQueryParam(query.equipamento),
        equipamentos: enumSetQueryParam(query.equipamentosAluno),
        hasVideo: query.somenteComVideo ? true : null,
        favoritos: query.somenteFavoritos ? true : null,
        page: query.page,
      );
    });
