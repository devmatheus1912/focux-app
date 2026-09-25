import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('habito detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/habitos/screens/habito_detail_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('habitCoaching'));
    expect(screen, contains('habitoStickyPersonal'));
    expect(screen, contains('habitoStickyAluno'));
    expect(screen, contains('desativar'));
    expect(screen, contains('toggleHoje'));
    expect(screen, contains('.buscar('));
    expect(screen, contains('habitoResumoLine'));
    expect(screen, contains('emphasize: false'));
    expect(screen, isNot(contains('emphasize: true')));
    expect(screen, contains('habitoDesativadoChip'));
    expect(screen, contains('habitoLembreteLine'));
    expect(screen, contains('habitoChecksLine'));
    expect(screen, contains('Lista'));
    expect(screen, contains("label: 'Hoje'"));
    expect(screen, contains("'/dashboard/aluno'"));
    expect(screen, isNot(contains('freshness: freshness')));
    expect(screen, isNot(contains('onPressed: () {}')));
    expect(screen, isNot(contains('meusHabitos')));
    expect(screen, isNot(contains('getHome')));
    expect(screen, contains("'/alunos/\${habito.alunoId}'"));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('onTap: () {}')));
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
