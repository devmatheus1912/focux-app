import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('tokens strip showcase cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/qa/screens/tokens_strip_showcase_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
