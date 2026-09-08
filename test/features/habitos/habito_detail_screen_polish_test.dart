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
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('habitCoaching'));
    expect(screen, contains('habitoStickyPersonal'));
    expect(screen, contains('habitoStickyAluno'));
    expect(screen, contains('desativar'));
    expect(screen, contains('toggleHoje'));
    expect(screen, contains("'/alunos/\${habito.alunoId}'"));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('onTap: () {}')));
  });
}
