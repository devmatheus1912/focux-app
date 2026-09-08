import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('engajamento cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/evolucao/screens/engajamento_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showEngajamentoHelpSheet'));
    expect(screen, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(screen, isNot(contains("safePopOrGo(context, '/evolucao')")));
    expect(screen, contains("'/alunos/\${widget.alunoId}/evolucao'"));
    expect(screen, contains("'/alunos/\${widget.alunoId}/chat'"));
    expect(screen, contains('engajamentoEventoRota'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('ListView.builder'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
