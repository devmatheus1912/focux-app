import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('novo exercicio biblioteca polish', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/add_exercicio_screen.dart',
    );

    expect(screen, contains('Semantics('));
    expect(screen, contains('Perfil rápido'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, isNot(contains('_EnumPicker')));
    expect(screen, contains('showAddExercicioFiltersSheet'));
    expect(screen, contains('showAddExercicioEnumPicker'));
    expect(screen, contains('exercicioId'));
    expect(screen, contains('S.of(context)'));
    expect(screen, contains('atualizar'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxInsetPickerRow'));
    expect(screen, contains('AlunoInsetFormField'));
  });
}
