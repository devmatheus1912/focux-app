import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('biblioteca: chips de grupo combináveis + lista A–Z; sem abas', () {
    final panel = File(
      'lib/features/treinos/widgets/exercise_library_panel.dart',
    ).readAsStringSync();
    final templates = File(
      'lib/features/exercicios/screens/widgets/template_split_picker.dart',
    ).readAsStringSync();

    final chips = File(
      'lib/features/treinos/widgets/exercise_group_chips.dart',
    ).readAsStringSync();
    expect(chips, contains('exercicioPickerStatsProvider'));
    expect(panel, contains('ExerciseGroupChips'));
    expect(panel, contains('Set<GrupoMuscular> _grupos'));
    expect(panel, contains('Mais usados'));
    expect(panel, contains('Favoritos'));
    expect(panel, isNot(contains('ExerciseLibraryBrowseMode')));
    expect(panel, isNot(contains('AlunoSegmentedChoice')));
    expect(panel, isNot(contains('FxSettingsTile')));
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
