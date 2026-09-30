import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ranking cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/ranking/screens/ranking_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('rankingComoCalculamosTitle'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('rankingCarregarMais'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('Pódio do Mês')));
    expect(screen, contains('rankingBuscarHint'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('rankingCrescerBase'));
    expect(screen, contains('rankingAssinatura'));
    expect(screen, contains('rankingAlunosLabel'));
    expect(screen, isNot(contains('rankingDescontoLabel')));
    expect(screen, contains('FxInputDeco.build'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
  });
}
