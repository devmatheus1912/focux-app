import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('assinatura cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/assinatura/screens/assinatura_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
