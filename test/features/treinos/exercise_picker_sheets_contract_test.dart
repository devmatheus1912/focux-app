import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picker sheets extraídos para widgets reutilizáveis', () {
    final library = File(
      'lib/features/treinos/widgets/exercise_library_panel.dart',
    ).readAsStringSync();
    final filters = File(
      'lib/features/treinos/widgets/exercise_picker_filter_sheet.dart',
    ).readAsStringSync();
    final prescription = File(
      'lib/features/treinos/widgets/prescription_editor_sheet.dart',
    ).readAsStringSync();

    expect(library, contains('class ExerciseLibraryPanel'));
    expect(library, contains('FxSettingsGroup'));
    expect(library, contains('ExerciseLibraryBrowseMode'));
    expect(library, contains('Recentes'));
    expect(filters, contains('FxInsetPickerOption.list'));
    expect(filters, contains('edgeToEdgeRows: true'));
    expect(filters, isNot(contains('_FilterPickerTile')));
    expect(prescription, contains('AlunoSegmentedChoice'));
    expect(prescription, contains('FxSettingsGroup'));
    expect(prescription, contains('_PrescriptionRepsRow'));
    expect(
      File(
        'lib/features/treinos/screens/widgets/exercise_picker_filter_bar.dart',
      ).readAsStringSync(),
      allOf(contains('Expanded('), contains('expanded: true')),
    );
  });
}
