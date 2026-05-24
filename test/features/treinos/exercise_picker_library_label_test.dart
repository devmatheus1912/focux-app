import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_library_label.dart';

void main() {
  group('exercisePickerLibrarySubtitle', () {
    test('favoritos vazio explica total', () {
      expect(
        exercisePickerLibrarySubtitle(
          filteredCount: 0,
          totalCount: 141,
          filter: const ExercisePickerFilter(somenteFavoritos: true),
        ),
        'Nenhum favorito ainda · 141 na biblioteca',
      );
    });

    test('filtro ativo mostra contagem parcial', () {
      expect(
        exercisePickerLibrarySubtitle(
          filteredCount: 38,
          totalCount: 141,
          filter: const ExercisePickerFilter(somenteComVideo: true),
        ),
        '38 com estes filtros · 141 no total',
      );
    });
  });
}
