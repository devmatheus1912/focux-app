import '../../exercicios/data/exercicio_repository.dart';
import 'exercise_picker_sort.dart';

/// Termos mais buscados por personais na montagem de treino.
const curatedExerciseSearchTerms = [
  'supino',
  'agachamento',
  'remada',
  'desenvolvimento',
  'puxada',
  'leg press',
  'rosca',
  'triceps',
];

List<Exercicio> curatedPickerSuggestions(
  Iterable<Exercicio> items, {
  required Set<int> alreadyInTreinoIds,
  int limit = 6,
}) {
  final pool = sortExerciciosForPicker(
    items,
    alreadyInTreinoIds: alreadyInTreinoIds,
  );
  final picked = <Exercicio>[];
  final seen = <int>{};

  for (final term in curatedExerciseSearchTerms) {
    if (picked.length >= limit) break;
    for (final exercicio in pool) {
      if (seen.contains(exercicio.id)) continue;
      final haystack =
          '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} ${exercicio.equipamento ?? ''}'
              .toLowerCase();
      if (haystack.contains(term)) {
        picked.add(exercicio);
        seen.add(exercicio.id);
        break;
      }
    }
  }

  for (final exercicio in pool) {
    if (picked.length >= limit) break;
    if (alreadyInTreinoIds.contains(exercicio.id)) continue;
    if (seen.add(exercicio.id)) picked.add(exercicio);
  }

  return picked;
}
