import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ativar aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/ativar_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('AuthLegalConsentText'));
    expect(screen, contains('AutofillHints.newPassword'));
    expect(screen, contains('PersonalSlugStore.save'));
    expect(screen, contains("context.go('/dashboard/aluno')"));
  });

  test('e-mail novo do aluno importado só entra com código', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/ativar_aluno_screen.dart',
    );
    expect(screen, contains('enviarCodigoAtivacao'));
    expect(screen, contains('AutofillHints.oneTimeCode'));
    expect(screen, contains('codigoEmail:'));
    expect(screen, contains('ativarCodigoPrimeiro'));
  });
}
