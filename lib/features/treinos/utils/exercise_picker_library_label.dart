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
      primary: '$filteredCount filtrados',
      secondary: '$totalCount no total',
    );
  }
  return ExercisePickerLibraryLines(
    primary: '$filteredCount exercícios',
    secondary: null,
  );
}

/// Uma linha para CTAs compactos.
String exercisePickerLibrarySubtitle({
  required int filteredCount,
  required int totalCount,
  required ExercisePickerFilter filter,
}) {
  final lines = exercisePickerLibraryLines(
    filteredCount: filteredCount,
    totalCount: totalCount,
    filter: filter,
  );
  if (lines.secondary == null) return lines.primary;
  return '${lines.primary} · ${lines.secondary}';
}

String buscarTabEmptyTitle({
  required ExercisePickerFilter filter,
  required String query,
}) {
  if (filter.somenteFavoritos) {
    return 'Nenhum exercício favorito';
  }
  if (query.trim().length >= 2) {
    return 'Nada encontrado para "$query"';
  }
  if (filter.somenteComVideo) {
    return 'Nenhum exercício com vídeo';
  }
  if (filter.isActive) {
    return 'Nenhum exercício com estes filtros';
  }
  return 'Biblioteca vazia';
}

String buscarTabEmptyMessage({required ExercisePickerFilter filter}) {
  if (filter.somenteFavoritos) {
    return 'Favorite exercícios na biblioteca para vê-los aqui com um toque.';
  }
  return 'Tente outro termo ou limpe os filtros para ver toda a biblioteca.';
}
