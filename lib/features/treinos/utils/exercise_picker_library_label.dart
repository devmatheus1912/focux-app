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

String buscarTabEmptyMessage({
  required ExercisePickerFilter filter,
  int? totalCount,
}) {
  if (filter.somenteFavoritos) {
    final total = totalCount;
    final suffix =
        total != null ? 'os $total disponíveis' : 'a biblioteca completa';
    return 'Favorite exercícios na biblioteca ou explore $suffix '
        'para montar sua lista rápida.';
  }
  if (filter.somenteComVideo) {
    return 'Nenhum exercício com vídeo ou GIF nesta combinação de filtros. '
        'Limpe os filtros ou grave sua demonstração ao selecionar um exercício.';
  }
  return 'Tente outro termo, abra a biblioteca completa ou limpe os filtros.';
}
