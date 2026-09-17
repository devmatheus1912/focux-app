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
    final pdf = readScreenSourceBundle(
      'lib/features/relatorio/utils/relatorio_pdf_export.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('Exportar relatório em PDF'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains("value: 'checkin'"));
    expect(screen, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(screen, isNot(contains('_PeriodPill')));

    expect(pdf, contains('_pdfHeader'));
    expect(pdf, contains('FOCUX'));
    expect(pdf, contains('relatorioPdfBrandLabel'));
    expect(pdf, contains('_pdfBrand'));

    expect(global, contains('fxScreenA11yScope'));
    expect(global, isNot(contains('FxSettingsGroup')));
    expect(global, contains('OperationalMetricTile'));
    expect(global, contains('FxHelpIconButton'));
    expect(global, contains('relatoriosHubViewed'));
    expect(global, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(global, isNot(contains('dashboardHeroMutedOnTealStyle')));
    expect(global, isNot(contains('Colors.white70')));
  });
}
