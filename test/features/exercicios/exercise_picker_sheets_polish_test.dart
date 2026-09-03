import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('escolher exercício no padrão não usa chevron de rota', () {
    final sheet = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/padrao_exercicios_bottom_sheet.dart',
    );
    expect(sheet, contains('picker: true'));
    expect(sheet, contains('class _ExerciseChoiceTile'));
  });

  test('substituir exercício no padrão não usa chevron de rota', () {
    final sheet = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart',
    );
    expect(sheet, contains('picker: true'));
    expect(sheet, contains('class _AlternativaTile'));
    expect(sheet, contains('OutlinedButton.icon'));
  });

  test('template split escolhe no picker certo', () {
    final sheet = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/template_split_picker.dart',
    );
    expect(sheet, contains('picker: true'));
    expect(sheet, contains('class _TemplateTile'));
  });
}
