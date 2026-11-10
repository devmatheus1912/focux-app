import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Escolher data no app é sempre o calendário da folha do kit
/// (`showFxCalendarioSheet`); o diálogo do sistema não volta.
void main() {
  test('nenhum showDatePicker em lib/', () {
    final ofensores = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('showDatePicker(')) {
        ofensores.add(f.path);
      }
    }
    expect(ofensores, isEmpty, reason: 'Use showFxCalendarioSheet');
  });
}
