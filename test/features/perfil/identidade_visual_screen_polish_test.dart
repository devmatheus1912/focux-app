import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('identidade visual cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/identidade_visual_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('FxErrorState'),
        contains('ref.invalidate'),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
      ),
    );
  });

  test('identidade visual usa CTA inset e mantém paywall e preview', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/identidade_visual_screen.dart',
    );
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('identidadeHasWhiteLabel'));
    expect(screen, contains('Assinar Enterprise'));
    expect(screen, contains('_LiveBrandHero'));
    expect(screen, contains('_CuratedPaletteGrid'));
    expect(screen, contains('_LogoUploadRing'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, isNot(contains('OutlinedButton')));
    expect(screen, isNot(contains('Editor da landing (Enterprise)')));
  });
}
