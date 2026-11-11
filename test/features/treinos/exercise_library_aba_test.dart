import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';
import 'package:focux_app/features/treinos/widgets/exercise_library_panel.dart';

void main() {
  test('aba vira o filtro do servidor', () {
    expect(exerciseLibraryAbaApi(ExerciseLibraryAba.todos), isNull);
    expect(exerciseLibraryAbaApi(ExerciseLibraryAba.meus), 'MEUS');
    expect(exerciseLibraryAbaApi(ExerciseLibraryAba.focux), 'FOCUX');
  });

  test('"Meus" ignora os filtros automáticos e mantém os escolhidos', () {
    final auto = {GrupoMuscular.values.first};
    final escolhido = GrupoMuscular.values.last;
    const filtro = ExercisePickerFilter(
      filtrarPorAluno: true,
      somenteFavoritos: true,
    );
    final meus = exerciseLibraryFiltrosDaAba(
      ExerciseLibraryAba.meus,
      grupos: {...auto, escolhido},
      gruposAutomaticos: auto,
      filtro: filtro,
    );
    expect(meus.grupos, {escolhido});
    expect(meus.filtro.filtrarPorAluno, isFalse);
    expect(meus.filtro.somenteFavoritos, isTrue);

    final todos = exerciseLibraryFiltrosDaAba(
      ExerciseLibraryAba.todos,
      grupos: auto,
      gruposAutomaticos: auto,
      filtro: filtro,
    );
    expect(todos.grupos, auto);
    expect(todos.filtro.filtrarPorAluno, isTrue);
  });
}
