import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('assinatura cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/assinatura/screens/assinatura_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });

  test('assinatura first paint usa paywall/home (não dual GET)', () {
    final screen = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    );
    expect(screen, contains('paywallHomeProvider'));
    expect(screen, contains('ref.watch(paywallHomeProvider)'));
    expect(screen, isNot(contains('ref.watch(planosProvider)')));
    expect(screen, isNot(contains('ref.watch(paywallVitrineProvider)')));

    final repo = File(
      'lib/features/assinatura/data/assinatura_repository.dart',
    ).readAsStringSync();
    expect(repo, contains('/api/planos/paywall/home'));
    expect(repo, contains('getPaywallHome'));
  });
}
