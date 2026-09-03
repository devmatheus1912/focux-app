import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('seedFromHome'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('IndexedStack'));
    expect(screen, contains('financeiroViewed'));
    expect(screen, contains('financeiroHelpOpened'));
    expect(screen, contains('coin'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('PopupMenuButton')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains('Icons.dashboard')));
    expect(screen, isNot(contains('bar_chart')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
  });
}
