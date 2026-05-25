import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assinatura paywall 10/10 com legal e conversao', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    final layout = File(
      'lib/features/assinatura/screens/claude_paywall_layout.dart',
    ).readAsStringSync();
    final legal = File('lib/core/legal/focux_legal.dart').readAsStringSync();

    expect(screen, contains("part 'claude_paywall_layout.dart'"));
    expect(screen, contains('focux_legal.dart'));
    expect(screen, contains('useMesh: true'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('Gerenciar assinatura na loja'));
    expect(screen, contains('Fazer upgrade para Enterprise'));

    expect(layout, contains('Termos de uso'));
    expect(layout, contains('Política de privacidade'));
    expect(layout, contains('FocuxLegal.openTerms'));
    expect(layout, contains('AnimatedSwitcher'));
    expect(layout, contains('annualSavingsLabel'));

    expect(legal, contains('termos.html'));
    expect(legal, contains('privacidade.html'));
  });
}
