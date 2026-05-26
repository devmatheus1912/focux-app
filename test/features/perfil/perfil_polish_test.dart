import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('perfil usa polish 10/10: a11y, acentos e contraste', () {
    final screen = File(
      'lib/features/perfil/screens/perfil_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('BrandPalette.deep(primaryColor)'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('semanticsLabel:'));
    expect(screen, contains('Não informado'));
    expect(screen, contains('Política de privacidade'));
    expect(screen, contains('Migração Focux'));
    expect(screen, contains('segurança'));
    expect(screen, isNot(contains('Nao informado')));
    expect(screen, isNot(contains('Politica de privacidade')));
  });
}
