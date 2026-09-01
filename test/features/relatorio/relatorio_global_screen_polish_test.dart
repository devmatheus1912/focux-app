import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio global cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_global_screen.dart',
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
    expect(screen, contains('relatoriosHubViewed'));
    expect(screen, contains('/alunos/'));
    expect(screen, contains('/relatorio'));
    expect(screen, contains('extra:'));
    expect(screen, isNot(contains('constrainWidth: false')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('bar-chart-2')));
    expect(screen, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(screen, isNot(contains('totalPrescritos')));
  });
}
