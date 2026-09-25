import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('lead detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/lead_detail_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, isNot(contains('showDatePicker')));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('leadStickyP0Label'));
    expect(screen, contains('leadConverterRoute'));
    expect(screen, isNot(contains('.converter(')));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('leadHubSubtitle'));
    expect(screen, contains('leadInteracoesMetricHint'));
    expect(screen, contains('leadOrigemLabel'));
    expect(screen, contains('leadDiasNoFunilValue'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('leadDetailSecoes'));
    expect(screen, contains('Lista'));
    expect(screen, contains('Kanban'));
    expect(screen, contains("'/leads/kanban'"));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('freshness: freshnessLabel')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('PopupMenuButton')));
    expect(screen, isNot(contains('onTap: () {}')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
