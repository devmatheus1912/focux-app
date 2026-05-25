import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('/planos redireciona para assinatura no router', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(router, contains("path: '/planos'"));
    expect(router, contains("return '/assinatura'"));
    expect(router, isNot(contains('/planos-legado')));
  });

  test('enterprise promo usa loja no app nativo', () {
    final promo = File(
      'lib/features/planos/screens/enterprise_promo_screen.dart',
    ).readAsStringSync();

    expect(promo, contains('subscriptionUsesNativeStore'));
    expect(promo, contains("'/assinatura'"));
  });
}
