import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('chat inbox cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/chat_inbox_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
      ),
    );
    expect(screen, contains('alunosHomeProvider'));
    expect(screen, contains('SkeletonList'));
    expect(screen, isNot(contains('Center(child: FxLoading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('chatInboxViewed'));
    expect(screen, contains('inboxHome(q:'));
    expect(screen, contains('chatInboxQueryProvider'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('hubCount:'));
    expect(screen, contains('Nova mensagem'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('IndexedStack'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
