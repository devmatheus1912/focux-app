import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('suporte web redirect cumpre contrato pré-lançamento', () {
    final screen = readScreenSourceBundle(
      'lib/features/suporte/screens/suporte_web_redirect_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FocuxLegal.openSupport'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, isNot(contains('SuporteRepository')));
    expect(screen, isNot(contains('/api/suporte/tickets')));
    expect(screen, isNot(contains('/api/suporte/chat')));
  });
}
