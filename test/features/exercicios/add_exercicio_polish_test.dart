import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('novo exercicio biblioteca polish', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/add_exercicio_screen.dart',
    );

    expect(screen, contains("'Novo exercício'"));
    expect(screen, contains('Erro ao cadastrar exercício.'));
    expect(screen, contains('Novo exercício'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Cadastrar exercício'));
    expect(screen, contains('Perfil rápido'));
    expect(screen, contains('selectedColor: primary'));
    expect(screen, contains('Colors.white'));
    expect(screen, contains('Fechar seletor'));
    expect(screen, isNot(contains('DropdownButtonFormField')));

    expect(screen, contains('showAddExercicioFiltersSheet'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxInsetPickerRow'));
    expect(screen, contains('AlunoInsetFormField'));
  });
}
