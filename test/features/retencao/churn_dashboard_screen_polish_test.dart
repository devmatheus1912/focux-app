import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alunos em risco cumpre contrato Tier S+', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/retencao/screens/churn_dashboard_screen.dart',
      ),
      readScreenSourceBundle(
        'lib/features/retencao/widgets/retencao_acoes_sheet.dart',
      ),
      readScreenSourceBundle(
        'lib/features/retencao/utils/retencao_display.dart',
      ),
    ].join('\n');
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxMetricStrip'));
    expect(screen, contains('FxActionRow'));
    expect(screen, contains('FxChoiceStrip'));
    expect(screen, contains('mostrarFiltros'));
    expect(screen, contains('filaSemAluno'));
    expect(screen, contains('listarBase'));
    expect(screen, contains('getHome'));
    expect(screen, contains('showRetencaoAcoesSheet'));
    expect(screen, contains('retencaoEmptyTitle'));
    expect(screen, contains('FxEmptyAction'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('retencaoHubViewed'));
    expect(screen, contains('alertaRiscoOpened'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxKeyboardPopScope'));
    expect(screen, contains("'/winback'"));
    expect(screen, contains("'/dunning'"));
    expect(screen, contains('retencaoEntradaHistorico'));
    expect(screen, contains('retencaoEntradaCobranca'));
    // O que saiu desta tela
    expect(screen, isNot(contains('showRetencaoCatalogSheet')));
    expect(screen, isNot(contains('Base toda')));
    expect(screen, isNot(contains('Ver todos')));
    expect(screen, isNot(contains('Hubs relacionados')));
    expect(screen, isNot(contains('Satélites')));
    expect(screen, isNot(contains("icon: 'route'")));
    expect(screen, isNot(contains('Saúde da base')));
    expect(screen, isNot(contains('Risco de cancelar')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
