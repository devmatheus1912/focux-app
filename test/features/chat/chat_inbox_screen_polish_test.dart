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
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
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
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('chatInboxViewed'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
