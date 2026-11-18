import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('picker sheets extraídos para widgets reutilizáveis', () {
    final library =
        File(
          'lib/features/treinos/widgets/exercise_library_panel.dart',
        ).readAsStringSync();
    final filters =
        File(
          'lib/features/treinos/widgets/exercise_picker_filter_sheet.dart',
        ).readAsStringSync();
    final prescription = readScreenSourceBundle(
      'lib/features/treinos/widgets/prescription_editor_sheet.dart',
    );

    expect(library, contains('class ExerciseLibraryPanel'));
    expect(library, contains('FxSettingsGroup'));
    expect(library, contains('ExerciseGroupChips'));
    expect(library, contains('ExerciseAlphaRail'));
    expect(library, contains('Recentes'));
    expect(library, contains('Mais usados'));
    expect(filters, contains('FxInsetPickerOption.list'));
    expect(filters, contains('edgeToEdgeRows: true'));
    // As folhas do "Outro" moram num arquivo só, usado pelas válidas e pelos grupos.
    expect(File('lib/features/treinos/widgets/prescricao_pickers.dart').readAsStringSync(),
        contains('showFxInsetPickerSheet'));
    expect(prescription, contains('FxSettingsTile'));
    expect(prescription, contains('FxSettingsGroup'));
    expect(prescription, isNot(contains('prescriptionGroupHeader')));
    expect(prescription, contains('prescriptionMaisDetalhes'));
    expect(prescription, contains('_openRepsSheet'));
    expect(prescription, isNot(contains('AlunoSegmentedChoice')));
    expect(prescription, isNot(contains("header: 'Volume'")));
    expect(
      File(
        'lib/features/treinos/screens/widgets/exercise_picker_chip.dart',
      ).readAsStringSync(),
      contains('minHeight: 44'),
    );
  });
}
