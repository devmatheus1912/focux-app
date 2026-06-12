import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_microcopy.dart';

void main() {
  test('FocuxMicrocopy exposes PT-BR action labels', () {
    expect(FocuxMicrocopy.tentarNovamente, 'Tentar novamente');
    expect(FocuxMicrocopy.cancelar, 'Cancelar');
    expect(FocuxMicrocopy.salvar, 'Salvar');
    expect(FocuxMicrocopy.algoDeuErrado, contains('Tente novamente'));
    expect(FocuxMicrocopy.version, isNotEmpty);
  });

  test('hub microcopy modules exist', () {
    for (final path in FocuxMicrocopy.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
  });

  test('module microcopy uses Portuguese section titles', () {
    final dashboard =
        File('lib/features/dashboard/utils/dashboard_microcopy.dart')
            .readAsStringSync();
    expect(dashboard, contains('Panorama financeiro'));
    expect(dashboard, contains('Ver prioridades'));

    final aluno360 =
        File('lib/features/alunos/utils/aluno360_microcopy.dart')
            .readAsStringSync();
    expect(aluno360, contains('Evolução inteligente'));
  });
}
