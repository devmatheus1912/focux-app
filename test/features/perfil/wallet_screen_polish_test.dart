import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('wallet cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/perfil/screens/wallet_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('FxChoiceStrip'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains("safePopOrGo(context, '/perfil')"));
    expect(screen, contains('perfilWalletProvider'));
    expect(screen, contains('Alterar chave'));
    // Troca de chave: valor novo na folha e o aparelho confirma.
    expect(screen, contains('walletTrocarConfirmMessage'));
    expect(screen, contains('confirmarNoAparelhoProvider'));
    // Salvar só com alteração; sem banco, sem cartão de cabeçalho, sem frescor.
    expect(screen, contains('_hasUnsavedChanges'));
    expect(screen, isNot(contains('AlunoSegmentedChoice')));
    expect(screen, isNot(contains('bancoCtrl')));
    expect(screen, isNot(contains('FxHubHeader')));
    expect(screen, isNot(contains('FxHubFreshness')));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, isNot(contains('FxSettingsTile')));
  });
}
