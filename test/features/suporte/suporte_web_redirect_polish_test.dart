import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('suporte web redirect cumpre contrato pré-lançamento', () {
    final screen = readScreenSourceBundle(
      'lib/features/suporte/screens/suporte_web_redirect_screen.dart',
    );
    expect(screen, contains('FocuxLegal.openSupport'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('SuporteRepository')));
    expect(screen, isNot(contains('/api/suporte/tickets')));
    expect(screen, isNot(contains('/api/suporte/chat')));
  });

  test('perfil aponta suporte para o site', () {
    final perfil = readScreenSourceBundle(
      'lib/features/perfil/widgets/perfil_conta_seguranca_section.dart',
    );
    expect(perfil, contains('FocuxLegal.openSupport'));
    expect(perfil, contains('focuxpersonal.com/suporte'));
    expect(perfil, isNot(contains("push('/suporte')")));
    expect(perfil, isNot(contains('Central no app')));
  });
}
