import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toda folha da Evolução passa pelo kit: sem diálogo, seletor nativo nem linha crua.
void main() {
  test('sem showDialog, showDatePicker ou ListTile em features/evolucao', () {
    final arquivos = Directory('lib/features/evolucao')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final arquivo in arquivos) {
      final codigo = arquivo.readAsStringSync();
      for (final proibido in ['showDialog', 'showDatePicker', 'ListTile(']) {
        final sem = codigo.replaceAll('FxSatelliteListTile(', '');
        expect(sem.contains(proibido), isFalse, reason: '${arquivo.path}: $proibido');
      }
    }
  });
}
