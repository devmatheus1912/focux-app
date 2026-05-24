import 'exercise_picker_filter.dart';

/// Subtítulo contextual do seletor de biblioteca (contador honesto com filtros).
String exercisePickerLibrarySubtitle({
  required int filteredCount,
  required int totalCount,
  required ExercisePickerFilter filter,
}) {
  if (filter.somenteFavoritos && filteredCount == 0) {
    return 'Nenhum favorito ainda · $totalCount na biblioteca';
  }
  if (filteredCount == 0 && filter.isActive) {
    return 'Nenhum com estes filtros · $totalCount no total';
  }
  if (filter.isActive && filteredCount != totalCount) {
    return '$filteredCount com estes filtros · $totalCount no total';
  }
  return '$filteredCount exercícios na biblioteca';
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
