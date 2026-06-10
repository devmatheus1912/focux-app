import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro usa polish 10/10: shell fino e tab extraída', () {
    final shell = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_screen.dart',
    );
    final tab = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    );

    expect(shell, contains('FxContentWidthLimiter'));
    expect(shell, contains('FinanceiroMensalidadesTab'));
    expect(shell, contains('TabBarView'));
    expect(shell, isNot(contains('class _MensalidadesTab')));
    expect(shell, isNot(contains('_MiniAction')));

    expect(tab, contains('class FinanceiroMensalidadesTab'));
    expect(tab, contains('class _MiniAction'));
    expect(tab, contains('DashboardErrorState'));
    expect(tab, contains('FeedbackHelper.showSuccess'));
  });
}
