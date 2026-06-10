import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_repository.dart';

class ExercisePickerFilter {
  const ExercisePickerFilter({
    this.espaco,
    this.equipamento,
    this.equipamentosAluno = const {},
    this.filtrarPorAluno = false,
    this.somenteFavoritos = false,
    this.somenteComVideo = false,
  });

  final Espaco? espaco;
  final Equipamento? equipamento;
  final Set<Equipamento> equipamentosAluno;
  final bool filtrarPorAluno;
  final bool somenteFavoritos;
  final bool somenteComVideo;

  bool get isActive =>
      espaco != null ||
      equipamento != null ||
      filtrarPorAluno ||
      somenteFavoritos ||
      somenteComVideo;

  ExercisePickerFilter copyWith({
    Espaco? espaco,
    Equipamento? equipamento,
    Set<Equipamento>? equipamentosAluno,
    bool? filtrarPorAluno,
    bool? somenteFavoritos,
    bool? somenteComVideo,
    bool clearEspaco = false,
    bool clearEquipamento = false,
    bool clearAluno = false,
  }) {
    return ExercisePickerFilter(
      espaco: clearEspaco ? null : (espaco ?? this.espaco),
      equipamento: clearEquipamento ? null : (equipamento ?? this.equipamento),
      equipamentosAluno:
          clearAluno ? const {} : (equipamentosAluno ?? this.equipamentosAluno),
      filtrarPorAluno:
          clearAluno ? false : (filtrarPorAluno ?? this.filtrarPorAluno),
      somenteFavoritos: somenteFavoritos ?? this.somenteFavoritos,
      somenteComVideo: somenteComVideo ?? this.somenteComVideo,
    );
  }

  static ExercisePickerFilter fromAlunoEquipamentos(Set<Equipamento> items) {
    if (items.isEmpty) return const ExercisePickerFilter();
    return ExercisePickerFilter(
      equipamentosAluno: items,
      filtrarPorAluno: true,
    );
  }
}

List<Exercicio> applyExercisePickerFilter(
  Iterable<Exercicio> items,
  ExercisePickerFilter filter,
) {
  return items.where((exercicio) {
    if (filter.somenteFavoritos && !exercicio.favoritado) return false;
    if (filter.somenteComVideo && !exercicio.hasPlayableMedia) return false;
    if (filter.espaco != null &&
        !exercicio.espacosCompativeis.contains(filter.espaco)) {
      return false;
    }
    if (filter.equipamento != null &&
        !exercicio.equipamentos.contains(filter.equipamento)) {
      return false;
    }
    if (filter.filtrarPorAluno && filter.equipamentosAluno.isNotEmpty) {
      final compativel =
          exercicio.equipamentos.isEmpty ||
          exercicio.equipamentos.any(filter.equipamentosAluno.contains);
      if (!compativel) return false;
    }
    return true;
  }).toList();
}

List<Exercicio> favoriteExercises(Iterable<Exercicio> items) {
  return items.where((exercicio) => exercicio.favoritado).toList();
}
