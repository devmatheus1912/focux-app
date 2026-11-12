import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('desafio detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/desafios/screens/desafio_detail_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('RefreshIndicator'));
    expect(
      screen,
      isNot(
        contains('TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom'),
      ),
    );
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('comunidadeGrupos'));
    expect(screen, contains('desafioStickyAlunoLabel'));
    expect(screen, contains('participar'));
    expect(screen, contains('encerrar'));
    expect(screen, contains('leaderboard'));
    expect(screen, contains('found.ranking'));
    expect(screen, isNot(contains('freshness: freshness')));
    expect(screen, contains('desafio.ativo'));
    expect(screen, contains('alunoMeProvider'));
    expect(screen, contains('marca: true'));
    expect(screen, isNot(contains('emphasize: true')));
    expect(screen, contains('desafioStickyAlunoPath'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('onTap: () {}')));
    // Redesign 11/11: ranking direto com barra; encerrar no ⋯.
    expect(screen, contains('DesafioLinhaRanking'));
    expect(screen, contains('desafioMeuResumo'));
    expect(screen, contains('showFxGroupedActionSheet'));
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('AlunoSegmentedChoice')));
    expect(screen, isNot(contains('FxActionChip')));
  });
}
