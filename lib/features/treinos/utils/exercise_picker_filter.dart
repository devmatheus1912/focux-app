import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_repository.dart';

class ExercisePickerFilter {
  const ExercisePickerFilter({
    this.espaco,
    this.equipamentos = const {},
    this.equipamentosAluno = const {},
    this.filtrarPorAluno = false,
    this.somenteFavoritos = false,
    this.somenteComVideo = false,
  });

  final Espaco? espaco;
  /// Ou entre os equipamentos escolhidos (halter ou polia).
  final Set<Equipamento> equipamentos;
  final Set<Equipamento> equipamentosAluno;
  final bool filtrarPorAluno;
  final bool somenteFavoritos;
  final bool somenteComVideo;

  bool get isActive =>
      espaco != null ||
      equipamentos.isNotEmpty ||
      filtrarPorAluno ||
      somenteFavoritos ||
      somenteComVideo;

  ExercisePickerFilter copyWith({
    Espaco? espaco,
    Set<Equipamento>? equipamentos,
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
      equipamentos:
          clearEquipamento ? const {} : (equipamentos ?? this.equipamentos),
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

  @override
  bool operator ==(Object other) =>
      other is ExercisePickerFilter &&
      other.espaco == espaco &&
      other.equipamentos.length == equipamentos.length &&
      other.equipamentos.containsAll(equipamentos) &&
      other.filtrarPorAluno == filtrarPorAluno &&
      other.somenteFavoritos == somenteFavoritos &&
      other.somenteComVideo == somenteComVideo &&
      other.equipamentosAluno.length == equipamentosAluno.length &&
      other.equipamentosAluno.containsAll(equipamentosAluno);

  @override
  int get hashCode => Object.hash(
    espaco,
    Object.hashAll(equipamentos.map((e) => e.name).toList()..sort()),
    filtrarPorAluno,
    somenteFavoritos,
    somenteComVideo,
    Object.hashAll(equipamentosAluno.map((e) => e.name).toList()..sort()),
  );
}

List<Exercicio> applyExercisePickerFilter(
  Iterable<Exercicio> items,
  ExercisePickerFilter filter, {
  bool serverFiltered = false,
}) {
  return items.where((exercicio) {
    if (!serverFiltered) {
      if (filter.somenteFavoritos && !exercicio.favoritado) return false;
      if (filter.somenteComVideo && !exercicio.hasPlayableMedia) return false;
      if (filter.espaco != null &&
          !exercicio.espacosCompativeis.contains(filter.espaco)) {
        return false;
      }
      if (filter.equipamentos.isNotEmpty &&
          !exercicio.equipamentos.any(filter.equipamentos.contains)) {
        return false;
      }
      if (filter.filtrarPorAluno && filter.equipamentosAluno.isNotEmpty) {
        final compativel =
            exercicio.equipamentos.isEmpty ||
            exercicio.equipamentos.any(filter.equipamentosAluno.contains);
        if (!compativel) return false;
      }
    }
    return true;
  }).toList();
}
