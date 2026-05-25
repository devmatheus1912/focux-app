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
    expect(screen, contains('_AssinaturaStickyGlassBar'));
    expect(screen, contains('BackdropFilter'));
    expect(screen, contains('_ClaudeLegalConsentLine'));
    expect(screen, contains('showLegalConsent'));
    expect(screen, contains('Gerenciar assinatura na loja'));
    expect(screen, contains('Fazer upgrade para Enterprise'));

    expect(layout, contains('_ClaudeLegalConsentLine'));
    expect(layout, contains('FocuxLegal.openTerms'));
    expect(layout, contains('FocuxLegal.openPrivacy'));
    expect(layout, contains('AnimatedSwitcher'));
    expect(layout, contains('annualSavingsLabel'));

    expect(legal, contains('termos.html'));
    expect(legal, contains('privacidade.html'));
  });
}
