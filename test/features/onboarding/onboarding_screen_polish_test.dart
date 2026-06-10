import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('onboarding cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/onboarding/screens/onboarding_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
