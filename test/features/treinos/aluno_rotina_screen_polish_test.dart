import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('rotina do aluno cumpre o contrato da tela', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/aluno_rotina_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxLoading'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxStickyActions'));
    expect(screen, contains('FichaSemana'));
    expect(screen, contains("'/alunos/\$alunoId/rotina'"));

    final aviso = File(
      'lib/features/treinos/utils/rotina_aviso.dart',
    ).readAsStringSync();
    expect(aviso, contains('showSuccessAction'));
    expect(aviso, isNot(contains('SnackBar(')));
  });
}
