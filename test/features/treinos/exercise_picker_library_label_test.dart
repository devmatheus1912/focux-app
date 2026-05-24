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
  });

  group('exercisePickerLibrarySubtitle', () {
    test('concatena linhas quando há secondary', () {
      expect(
        exercisePickerLibrarySubtitle(
          filteredCount: 0,
          totalCount: 141,
          filter: const ExercisePickerFilter(somenteFavoritos: true),
        ),
        'Sem favoritos · 141 no total',
      );
    });
  });
}
