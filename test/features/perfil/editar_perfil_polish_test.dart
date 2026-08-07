import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editar perfil usa polish: perfil, a11y e salvando', () {
    final screen = File(
      'lib/features/perfil/screens/editar_perfil_screen.dart',
    ).readAsStringSync();

    expect(screen, contains("subtitle: 'PERFIL'"));
    expect(screen, contains("loadingLabel: 'Salvando…'"));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Salvando alterações do perfil'));
    expect(screen, contains('showHint: false'));
    expect(screen, isNot(contains('google_fonts')));
  });
}
