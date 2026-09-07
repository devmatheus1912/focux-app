import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('analytics cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/analytics/screens/analytics_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('class _KpiCard')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('financeiroViewed'));
    expect(screen, contains('Ver retenção'));
    expect(screen, contains('FxErrorState'));
    expect(screen, isNot(contains('_InadimplenciaCard')));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('isDark'));
  });
}
