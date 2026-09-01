import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('hub de check-in do personal cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_personal_hub_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroupedList'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('checkinHubViewed'));
    expect(screen, isNot(contains('/checkin/executar')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
