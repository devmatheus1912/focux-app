import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('nps dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/nps/screens/nps_dashboard_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('chatThreadOpened'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('showNpsCatalogSheet'));
    expect(screen, contains('Ver todos'));
    expect(screen, contains("queryParameters['filtro']"));
    expect(screen, contains('isDark'));
  });
}
