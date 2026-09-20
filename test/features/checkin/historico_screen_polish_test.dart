import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('historico cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/historico_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('showBack: true'));
    expect(screen, contains("fallbackLocation: '/checkin/treinos'"));
    expect(screen, contains('ListView('));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('historicoDetalhePath'));
    expect(screen, contains('historicoStatusQuery'));
    expect(screen, contains('historicoGroupByStatus'));
    expect(screen, contains('_HistoricoStatusChip'));
    expect(screen, contains('_HistoricoSectionLabel'));
    expect(screen, contains('q: _query'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('onTapOutside'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains("icon: 'plus'")));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('FeedbackHelper.showError'));
  });
}
