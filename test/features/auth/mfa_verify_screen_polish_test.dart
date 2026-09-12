import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('mfa verify cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/mfa_verify_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('AuthGlassCard'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('authScrollPadding'));
    expect(screen, contains('ensureFooter: true'));
    expect(screen, contains('AutofillHints.oneTimeCode'));
    expect(screen, contains('form == null || !form.validate()'));
    expect(screen, contains('mapMfaVerifyError'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('safePostLoginPath'));
    expect(screen, contains('Verificação em duas etapas'));
    expect(screen, contains('Voltar ao login'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('liveRegion: true'));
    expect(screen, isNot(contains('FxShellScaffold')));
    expect(screen, isNot(contains('currentState!.validate')));
  });
}
