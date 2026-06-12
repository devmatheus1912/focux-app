import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('analytics usa polish: dados reais, a11y e erro', () {
    final screen = readScreenSourceBundle(
      'lib/features/analytics/screens/analytics_screen.dart',
    );

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('DashboardErrorState'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('data.wau'));
    expect(screen, contains('data.mau'));
    expect(screen, contains('data.retencaoD30'));
    expect(screen, contains('Semantics('));
    expect(screen, isNot(contains('cac = 42')));
    expect(screen, isNot(contains('totalAlunos * 79')));
    expect(screen, isNot(contains('79.0 / (churn')));
  });
}
