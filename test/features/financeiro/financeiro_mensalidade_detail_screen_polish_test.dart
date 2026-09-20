import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro mensalidade detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_mensalidade_detail_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFinanceiroMensalidadeHelpSheet'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('mensalidadeDetailMaisActions'));
    expect(screen, contains('mensalidadeDetailMaisSheetTitle'));
    expect(screen, contains('mensalidadeDetailMaisChipLabel'));
    expect(screen, contains('financeiroMensalidadeHubSubtitle'));
    expect(screen, contains('financeiroMensalidadeMesPorExtenso'));
    expect(screen, contains('financeiroMensalidadeDetailValorHint'));
    expect(screen, contains('_ValorMetricTile'));
    expect(screen, contains('FontFeature.tabularFigures'));
    expect(screen, contains('letterSpacing: 0'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains("safePopOrGo("));
    expect(screen, contains("'/financeiro'"));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('AlunoSegmentedChoice')));
  });
}
