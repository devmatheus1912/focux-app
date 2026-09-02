import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('assinatura review cumpre o esqueleto S6', () {
    final screen = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_review_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('ExpansionTile')));
    expect(screen, isNot(contains('fontSize: 28')));
    expect(screen, contains('assinaturaReviewConfirmLabel'));
  });
}
