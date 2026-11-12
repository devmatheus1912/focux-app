import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('composer do feed cumpre S7 form', () {
    final sheet = readScreenSourceBundle(
      'lib/features/feed/widgets/feed_composer_sheet.dart',
    );
    expect(sheet, contains('FxLiquidPrimaryButton'));
    // Uma caixa só: a primeira linha vira o título; sai o "T" e o chip.
    expect(sheet, contains('feedSepararTitulo'));
    expect(sheet, contains('Avisar os alunos'));
    expect(sheet, contains('Mostrar como dica'));
    expect(sheet, isNot(contains('FilterChip')));
    expect(sheet, isNot(contains('FxIcons.titulo')));
    expect(sheet, isNot(contains('agendaTituloGrupo')));
    expect(sheet, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(sheet, contains('LengthLimitingTextInputFormatter'));
    expect(sheet, isNot(contains('ElevatedButton')));
    expect(sheet, isNot(contains('showFxConfirmSheet')));
    expect(sheet, isNot(contains('viewInsets.bottom')));
    expect(sheet, isNot(contains('Navigator.of(context).pop')));
  });
}
