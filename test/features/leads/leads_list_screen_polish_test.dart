import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('leads list cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/leads_list_screen.dart',
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
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('leadListChipStatuses'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showLeadsListHelpSheet'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('_searchFocus'));
    expect(screen, contains('q: _query'));
    expect(screen, contains('leadShowsLimitBanner'));
    expect(screen, contains('/leads/kanban'));
    expect(screen, isNot(contains('_KanbanColumn')));
    expect(screen, isNot(contains('_KanbanCard')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains("icon: 'plus'")));
    expect(screen, isNot(contains('Icons.person_add')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
