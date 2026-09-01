import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('getHome('));
    expect(screen, contains('relatorioAlunoViewed'));
    expect(screen, contains('Exportar relatório em PDF'));
    expect(screen, isNot(contains('constrainWidth: false')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('_PeriodPill')));
    expect(screen, isNot(contains('_AderenciaRingPainter')));
  });
}
