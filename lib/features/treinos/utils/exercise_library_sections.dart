import '../../exercicios/data/exercicio_repository.dart';

class ExerciseLibrarySection {
  const ExerciseLibrarySection({
    required this.letter,
    required this.items,
  });

  final String letter;
  final List<Exercicio> items;
}

String exerciseLibrarySortLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final first = trimmed[0].toUpperCase();
  final code = first.codeUnitAt(0);
  if (code >= 65 && code <= 90) return first;
  if (code >= 48 && code <= 57) return '#';
  return '#';
}

List<ExerciseLibrarySection> buildExerciseLibrarySections(
  List<Exercicio> exercicios,
) {
  if (exercicios.isEmpty) return const [];

  final buckets = <String, List<Exercicio>>{};
  for (final exercicio in exercicios) {
    final letter = exerciseLibrarySortLetter(exercicio.nomeDisplay);
    buckets.putIfAbsent(letter, () => []).add(exercicio);
  }

  final letters = buckets.keys.toList()..sort((a, b) {
    if (a == '#') return -1;
    if (b == '#') return 1;
    return a.compareTo(b);
  });

  return [
    for (final letter in letters)
      ExerciseLibrarySection(letter: letter, items: buckets[letter]!),
  ];
}
