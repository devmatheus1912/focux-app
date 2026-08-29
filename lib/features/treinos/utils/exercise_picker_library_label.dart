import 'exercise_picker_filter.dart';

/// Linhas curtas para o seletor (evita truncar em uma linha).
class ExercisePickerLibraryLines {
  const ExercisePickerLibraryLines({required this.primary, this.secondary});

  final String primary;
  final String? secondary;
}

ExercisePickerLibraryLines exercisePickerLibraryLines({
  required int filteredCount,
  required int totalCount,
  required ExercisePickerFilter filter,
}) {
  if (filter.somenteFavoritos && filteredCount == 0) {
    return ExercisePickerLibraryLines(
      primary: 'Sem favoritos',
      secondary: '$totalCount no total',
    );
  }
  if (filteredCount == 0 && filter.isActive) {
    return ExercisePickerLibraryLines(
      primary: 'Nenhum com filtros',
      secondary: '$totalCount no total',
    );
  }
  if (filter.isActive && filteredCount != totalCount) {
    return ExercisePickerLibraryLines(
      primary: '$filteredCount com filtros',
      secondary: '$totalCount no total',
    );
  }
  return ExercisePickerLibraryLines(
    primary: '$filteredCount exercícios',
    secondary: null,
  );
}
