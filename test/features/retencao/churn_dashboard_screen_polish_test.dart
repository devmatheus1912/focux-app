import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('churn dashboard cumpre contrato Tier S+', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/retencao/screens/churn_dashboard_screen.dart',
      ),
      readScreenSourceBundle(
        'lib/features/retencao/widgets/retencao_acoes_sheet.dart',
      ),
    ].join('\n');
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('getHome'));
    expect(screen, contains('showRetencaoCatalogSheet'));
    expect(screen, contains('showRetencaoAcoesSheet'));
    expect(screen, contains('Escrever'));
    expect(screen, contains('Cobrar'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('retencaoEmptyTitle'));
    expect(screen, isNot(contains('Scores em breve')));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('/alunos?filtro=risco')));
    expect(screen, isNot(contains('class _ChurnScoreCard')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('alertaRiscoOpened'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('isDark'));
  });
}
