import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('business reports cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/business_reports_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('businessReportsViewed'));
    expect(screen, contains('/dunning'));
    expect(screen, isNot(contains('bar-chart-2')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('Icons.attach_money')));
  });
}
