import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('winback cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/winback/screens/winback_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('Buscar aluno'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('winbackHubViewed'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('emphasize: false'));
    expect(screen, contains('FxInputDeco.build'));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('Escrever'));
    expect(screen, contains('Cobrar'));
    expect(screen, contains('Saúde da base'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, contains('PopScope'));
    expect(screen, contains('Histórico win-back'));
    expect(screen, contains('showWinbackAcoesSheet'));
    expect(screen, contains('/alunos/\$id/chat'));
    expect(screen, contains('/financeiro?alunoId='));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSatellitePanel')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
