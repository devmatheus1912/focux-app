import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('evolucao comparativo cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/avaliacao/screens/evolucao_comparativo_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('.registrar('));
    expect(screen, contains("'/alunos/\${widget.alunoId}/evolucao'"));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('PopScope'));
    expect(screen, contains("'/alunos/\${widget.alunoId}/fotos'"));
    expect(screen, contains("label: 'Evolução'"));
    expect(screen, contains("label: 'Fotos'"));
    expect(screen, isNot(contains("label: 'Lista'")));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('percGordura'));
    expect(screen, contains('circCintura'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('person_add')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
