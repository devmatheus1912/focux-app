import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_library_label.dart';

void main() {
  group('exercisePickerLibraryLines', () {
    test('favoritos vazio usa linhas curtas', () {
      final lines = exercisePickerLibraryLines(
        filteredCount: 0,
        totalCount: 141,
        filter: const ExercisePickerFilter(somenteFavoritos: true),
      );
      expect(lines.primary, 'Sem favoritos');
      expect(lines.secondary, '141 no total');
    });

    test('filtro ativo usa linhas curtas', () {
      final lines = exercisePickerLibraryLines(
        filteredCount: 38,
        totalCount: 141,
        filter: const ExercisePickerFilter(somenteComVideo: true),
      );
      expect(lines.primary, '38 filtrados');
      expect(lines.secondary, '141 no total');
    });

    test('sem filtro usa total da biblioteca', () {
      final lines = exercisePickerLibraryLines(
        filteredCount: 187,
        totalCount: 187,
        filter: const ExercisePickerFilter(),
      );
      expect(lines.primary, '187 exercícios');
      expect(lines.secondary, isNull);
    });
  });

  group('buscarTabEmptyTitle', () {
    test('favoritos vazio', () {
      expect(
        buscarTabEmptyTitle(
          filter: const ExercisePickerFilter(somenteFavoritos: true),
          query: '',
        ),
        'Nenhum exercício favorito',
      );
    });

    test('busca sem resultado', () {
      expect(
        buscarTabEmptyTitle(
          filter: const ExercisePickerFilter(),
          query: 'xyz',
        ),
        'Nada encontrado para "xyz"',
      );
    });

    test('filtro com vídeo', () {
      expect(
        buscarTabEmptyTitle(
          filter: const ExercisePickerFilter(somenteComVideo: true),
          query: '',
        ),
        'Nenhum exercício com vídeo',
      );
    });
  });
}
