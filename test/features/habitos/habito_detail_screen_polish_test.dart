import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('habito detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/habitos/screens/habito_detail_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('constrainWidth: false'));
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
    expect(screen, contains('habitCoaching'));
    expect(screen, contains('habitoStickyAluno'));
    expect(screen, contains('desativar'));
    expect(screen, contains('toggleHoje'));
    expect(screen, contains('.buscar('));
    expect(screen, isNot(contains('emphasize: true')));
    expect(screen, contains('habitoLembreteLine'));
    expect(screen, contains('habitoChecksLine'));
    expect(screen, isNot(contains('freshness: freshness')));
    expect(screen, isNot(contains('onPressed: () {}')));
    expect(screen, isNot(contains('meusHabitos')));
    expect(screen, isNot(contains('getHome')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('onTap: () {}')));
    // Redesign 11/11: sem cartões, abas e "Lista"; desativar no ⋯.
    expect(screen, contains('marca: true'));
    expect(screen, contains('showFxGroupedActionSheet'));
    expect(screen, contains('.semana('));
    expect(screen, contains('habitoVezesPorSemana'));
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('AlunoSegmentedChoice')));
    expect(screen, isNot(contains('FxActionChip')));
  });

  test('hábito detalhe busca por id', () {
    final repo = readScreenSourceBundle(
      'lib/features/habitos/data/habito_repository.dart',
    );
    expect(repo, contains("get('/api/habitos/\$id')"));
    expect(repo, contains('Future<Habito> buscar(int id)'));
    expect(repo, contains("ativo: j['ativo'] as bool? ?? true"));
  });
}
