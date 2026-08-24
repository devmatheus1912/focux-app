import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('assinatura paywall com legal e conversao', () {
    final screen = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    );
    final layout = File(
      'lib/features/assinatura/screens/paywall_layout.dart',
    ).readAsStringSync();
    final legal = File('lib/core/legal/focux_legal.dart').readAsStringSync();

    expect(screen, contains("part 'paywall_layout.dart'"));
    expect(screen, contains('focux_legal.dart'));
    expect(screen, contains('useMesh: true'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('_AssinaturaStickyGlassBar'));
    expect(screen, contains('BackdropFilter'));
    expect(screen, contains('_PaywallLegalConsentLine'));
    expect(screen, contains('showLegalConsent'));
    expect(screen, contains('Gerenciar assinatura na loja'));
    expect(screen, contains('_focusEnterpriseProUpgrade'));

    expect(layout, contains('_PaywallLegalConsentLine'));
    expect(layout, contains('FocuxLegal.openTerms'));
    expect(layout, contains('FocuxLegal.openPrivacy'));
    expect(layout, contains('_paywallSecondaryText'));
    expect(layout, contains('_PaywallInlineNote'));

    expect(legal, contains('focuxpersonal.com/termos'));
    expect(legal, contains('focuxpersonal.com/privacidade'));
  });
}
