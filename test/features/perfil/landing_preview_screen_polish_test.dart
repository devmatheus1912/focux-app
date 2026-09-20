import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('landing preview cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/landing_preview_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('WebViewWidget'));
  });
}
