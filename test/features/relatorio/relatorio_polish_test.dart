import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio usa polish: cards, erro amigavel e a11y', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_screen.dart',
    );
    final global = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_global_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('Exportar relatório em PDF'));
    expect(screen, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(screen, isNot(contains('_PeriodPill')));

    expect(global, contains('fxScreenA11yScope'));
    expect(global, contains('FxSettingsGroup'));
    expect(global, contains('FxHelpIconButton'));
    expect(global, contains('relatoriosHubViewed'));
    expect(global, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(global, isNot(contains('dashboardHeroMutedOnTealStyle')));
    expect(global, isNot(contains('Colors.white70')));
  });
}
