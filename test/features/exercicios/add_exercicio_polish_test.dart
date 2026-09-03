import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('novo exercicio biblioteca polish', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/add_exercicio_screen.dart',
    );
    final enumPicker = File(
      'lib/features/exercicios/widgets/add_exercicio_enum_picker_sheet.dart',
    ).readAsStringSync();

    expect(screen, contains('Semantics('));
    expect(screen, contains('Perfil rápido'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, isNot(contains('_EnumPicker')));
    expect(screen, contains('showAddExercicioFiltersSheet'));
    final filters = File(
      'lib/features/exercicios/widgets/add_exercicio_filters_sheet.dart',
    ).readAsStringSync();
    expect(filters, contains('FxLiquidPrimaryButton'));
    expect(filters, isNot(contains('DashboardHomeActionChip')));
    expect(screen, contains('showAddExercicioEnumPicker'));
    expect(screen, contains('exercicioId'));
    expect(screen, contains('S.of(context)'));
    expect(screen, contains('atualizar'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, isNot(contains('DashboardHomeActionChip')));
    expect(screen, contains('FxInsetPickerRow'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showNovoExercicioHelpSheet'));
    expect(screen, isNot(contains('onHelpTap')));
    expect(screen, isNot(contains('showNovoExercicioIdentidadeHelpSheet')));
    expect(screen, isNot(contains('showNovoExercicioPerfilRapidoHelpSheet')));
    expect(screen, contains("'Unilateral'"));
    expect(screen, isNot(contains("header: 'Execução'")));
    expect(enumPicker, contains('edgeToEdgeRows: true'));
    expect(enumPicker, contains('FxInsetPickerOption.list'));
  });
}
