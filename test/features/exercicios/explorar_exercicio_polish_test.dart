import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('biblioteca: músculo + lista inset; sem segmento Movimento', () {
    final panel = File(
      'lib/features/treinos/widgets/exercise_library_panel.dart',
    ).readAsStringSync();
    final templates = File(
      'lib/features/exercicios/screens/widgets/template_split_picker.dart',
    ).readAsStringSync();

    expect(panel, contains('ExerciseLibraryBrowseMode.musculo'));
    expect(panel, contains('exercicioPickerStatsProvider'));
    expect(panel, contains('Grupos musculares'));
    expect(panel, isNot(contains('ExerciseLibraryBrowseMode.movimento')));
    expect(panel, isNot(contains("label: 'Movimento'")));
    expect(panel, isNot(contains('numeric: true')));
    expect(panel, isNot(contains('PadraoExerciciosBottomSheet')));

    expect(templates, contains('FxSettingsLayout.pageInset'));
    expect(templates, contains('buildTemplateSplitSections'));
    expect(templates, contains('templateSplitTileSubtitle'));
    expect(templates, contains("value: ''"));
    expect(templates, isNot(contains(r"value: '$dias")));
    expect(templates, contains('FxSettingsGroup('));
    expect(templates, contains('header: sections[s].header'));
    expect(templates, contains('header: _templateDayTitle'));
    expect(templates, isNot(contains('child: InkWell(')));
  });
}
