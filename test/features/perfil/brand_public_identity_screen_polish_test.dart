import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('brand public identity cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/brand_public_identity_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('ref.invalidate'));
  });
}
