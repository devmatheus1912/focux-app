import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('perfil ferramentas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/perfil_ferramentas_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('useMesh: true'));

    // Estados canônicos: skeleton no loading, FxErrorState com retry.
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('ref.invalidate'));
    expect(screen, isNot(contains('CircularProgressIndicator')));

    // Tokens em vez de literais e navegação segura ao voltar.
    expect(screen, contains('FxSettingsLayout.'));
    expect(screen, contains('BrandPalette.'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, isNot(contains('Color(0x')));
  });
}
