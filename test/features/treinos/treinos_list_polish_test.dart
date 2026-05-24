import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';

void main() {
  group('displayWorkoutName', () {
    test('corrige Forca para Força no card da biblioteca', () {
      expect(displayWorkoutName('Treino Forca'), 'Treino Força');
    });
  });

  test('treinos list sheet usa scroll e microcopy 10/10', () {
    final screen =
        File(
          'lib/features/treinos/screens/treinos_list_screen.dart',
        ).readAsStringSync();

    expect(screen, contains('isScrollControlled: true'));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, contains('BoxConstraints(maxHeight: maxHeight)'));
    expect(screen, contains('Atribuir a um aluno'));
    expect(screen, contains('control_point_duplicate_rounded'));
    expect(screen, contains('assignment_ind_rounded'));
    expect(screen, contains('displayWorkoutName(treino.nome)'));
    expect(screen, contains('_readyPlansLabel'));
    expect(screen, contains('segure para selecionar'));
  });
}
