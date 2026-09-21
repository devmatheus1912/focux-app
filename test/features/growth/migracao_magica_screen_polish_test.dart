import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('migracao magica cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/growth/screens/migracao_magica_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('UpgradePromptSheet'));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('migracaoIniciarLabel'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('migracaoEtapaLabel'));
    expect(screen, contains('FxWizardStickyBar'));
    expect(screen, contains('FxWizardStepDots'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('MigracaoMagicaDraftCache'));
    expect(screen, contains('MigracaoEtapa.acesso'));
    expect(screen, contains('migracaoVagasHint'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('FeatureGate')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
