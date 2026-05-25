import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planos legado redireciona para assinatura', () {
    final screen = File(
      'lib/features/planos/screens/planos_screen.dart',
    ).readAsStringSync();

    expect(screen, contains("context.go('/assinatura')"));
    expect(screen, isNot(contains('startTrial')));
  });

  test('enterprise promo usa loja no app nativo', () {
    final promo = File(
      'lib/features/planos/screens/enterprise_promo_screen.dart',
    ).readAsStringSync();

    expect(promo, contains('subscriptionUsesNativeStore'));
    expect(promo, contains("'/assinatura'"));
  });
}
