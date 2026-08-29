import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explorar por movimento segue picker inset e tiles de navegação', () {
    final panel = File(
      'lib/features/treinos/widgets/exercise_library_panel.dart',
    ).readAsStringSync();
    final templates = File(
      'lib/features/exercicios/screens/widgets/template_split_picker.dart',
    ).readAsStringSync();

    expect(panel, contains('ExerciseLibraryBrowseMode'));
    expect(panel, contains('exercicioPickerStatsProvider'));
    expect(panel, contains('FxSettingsGroup'));
    expect(panel, contains('FxSettingsTile'));
    expect(panel, isNot(contains('numeric: true')));
    expect(panel, isNot(contains('PadraoExerciciosBottomSheet')));

    expect(templates, contains('FxSettingsLayout.pageInset'));
    expect(templates, contains('_templateTileSubtitle'));
    expect(templates, contains("value: ''"));
    expect(templates, isNot(contains(r"value: '$dias")));
    expect(templates, contains('FxSettingsGroup('));
    expect(templates, contains('header: _templateDayTitle'));
    expect(templates, isNot(contains('child: InkWell(')));
  });
}
