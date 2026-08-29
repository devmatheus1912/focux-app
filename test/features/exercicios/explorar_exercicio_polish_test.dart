import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explorar por movimento segue picker inset e tiles de navegação', () {
    final grid = File(
      'lib/features/exercicios/screens/widgets/padrao_movimento_grid.dart',
    ).readAsStringSync();
    final templates = File(
      'lib/features/exercicios/screens/widgets/template_split_picker.dart',
    ).readAsStringSync();

    expect(grid, contains('FxInsetPickerOption.list'));
    expect(grid, contains('edgeToEdgeRows: true'));
    expect(grid, isNot(contains('numeric: true')));
    expect(grid, isNot(contains("value: '\${items[i].count}'")));

    expect(templates, contains('FxSettingsLayout.pageInset'));
    expect(templates, contains('_templateTileSubtitle'));
    expect(templates, contains("value: ''"));
    expect(templates, isNot(contains(r"value: '$dias")));
  });
}
