import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picker sheets extraídos para widgets reutilizáveis', () {
    final library = File(
      'lib/features/treinos/widgets/exercise_library_sheet.dart',
    ).readAsStringSync();
    final filters = File(
      'lib/features/treinos/widgets/exercise_picker_filter_sheet.dart',
    ).readAsStringSync();
    final prescription = File(
      'lib/features/treinos/widgets/prescription_editor_sheet.dart',
    ).readAsStringSync();

    expect(library, contains('showExerciseLibrarySheet'));
    expect(library, contains('FxSettingsGroup'));
    expect(filters, contains('StatefulWidget'));
    expect(filters, contains('Icons.check_rounded'));
    expect(prescription, contains('AlunoSegmentedChoice'));
    expect(
      File(
        'lib/features/treinos/utils/add_exercise_prescription_input.dart',
      ).readAsStringSync(),
      contains('resolveAddExercisePrescription'),
    );
  });
}
