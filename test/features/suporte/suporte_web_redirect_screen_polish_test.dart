import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('suporte web redirect cumpre contrato pré-lançamento', () {
    final screen = readScreenSourceBundle(
      'lib/features/suporte/screens/suporte_web_redirect_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('IntercomService.openMessenger'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, isNot(contains('SuporteRepository')));
    expect(screen, isNot(contains('/api/suporte/tickets')));
    expect(screen, isNot(contains('/api/suporte/chat')));
  });

  test('perfil abre suporte via Intercom', () {
    final perfil = readScreenSourceBundle(
      'lib/features/perfil/widgets/perfil_conta_seguranca_section.dart',
    );
    expect(perfil, contains('IntercomService.openMessenger'));
    expect(perfil, isNot(contains('FocuxLegal.openSupport')));
    expect(perfil, isNot(contains("push('/suporte')")));
    expect(perfil, isNot(contains('Central no app')));
  });
}
