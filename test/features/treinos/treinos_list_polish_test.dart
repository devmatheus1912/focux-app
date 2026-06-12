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
    final screen = [
      'lib/features/treinos/screens/treinos_list_screen.dart',
      'lib/features/treinos/utils/treinos_list_labels.dart',
    ].map((p) => File(p).readAsStringSync()).join('\n');

    expect(screen, contains('isScrollControlled: true'));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, contains('BoxConstraints(maxHeight: maxHeight)'));
    expect(screen, contains('Atribuir a um aluno'));
    expect(screen, contains('control_point_duplicate_rounded'));
    expect(screen, contains('assignment_ind_rounded'));
    expect(screen, contains('displayWorkoutName(treino.nome)'));
    expect(screen, contains('TreinosListLabels.readyPlans'));
    expect(screen, contains('segure para selecionar'));
  });
}
