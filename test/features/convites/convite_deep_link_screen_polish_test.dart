import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('convite deep link cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/convites/screens/convite_deep_link_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('Validando convite'));
    expect(screen, contains('Não foi possível abrir o convite'));
    expect(screen, contains('/register/aluno'));
    expect(screen, contains('/login'));
    expect(screen, contains('PersonalSlugStore'));
    expect(screen, contains('conviteRepositoryProvider'));
    expect(screen, isNot(contains('FxShellScaffold')));
  });
}
