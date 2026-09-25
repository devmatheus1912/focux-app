import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('qualidade operacional cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/qualidade_operacional_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('relatoriosHubViewed'));
    expect(screen, contains("'qualidade'"));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('heroGradientFrom')));
    expect(screen, contains('qualidadeTicketValueLabel'));
    expect(screen, contains('qualidadeTicketHint'));
    expect(screen, contains('qualidadeTicketUnavailable'));
    expect(screen, contains('OperationalMetricEmphasis.muted'));
    expect(screen, contains('TokensStrip.s6'));
    expect(screen, isNot(contains('formatBrlCurrency')));
  });
}
