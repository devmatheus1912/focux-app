import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_aluno_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/dashboard/aluno'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('/chat/aluno'));
    expect(screen, contains("'Pagas'"));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('subtitle: freshness'));
    expect(screen, contains("label: 'Atrasadas'"));
    expect(screen, contains("label: 'Vence'"));
    expect(screen, contains('financeiroAlunoProximoVencimentoValue'));
    expect(screen, contains('FocuxHubTypography.metric'));
    expect(screen, contains('showFinanceiroAlunoCobrancaSheet'));
    expect(screen, contains('mostrarPixMensalidade'));
    expect(screen, contains('circle-check'));
    expect(screen, isNot(contains('check-circle')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains("showError(context, '\$e')")));
  });
}
