import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alerta detalhe cumpre contrato Tier S+', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/alertas/screens/alerta_detalhe_screen.dart',
      ),
      readScreenSourceBundle(
        'lib/features/alertas/widgets/alerta_detalhe_situacao.dart',
      ),
    ].join('\n');
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('IaSafetyDisclaimer'));
    expect(screen, contains('alertasDetalheViewed'));
    expect(screen, contains('Melhorar com IA'));
    expect(screen, contains('alertaAdiarCtaLabel'));
    expect(screen, contains('enviarMensagemChat'));
    expect(screen, contains('showAlertaEnviarMensagemSheet'));
    expect(screen, contains('alertaEnviarMensagemCtaLabel'));
    expect(screen, contains('aplicarSugestaoIa'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('alertaHubSubtitle'));
    expect(screen, contains('alertaCheckinsMetricValue'));
    expect(screen, contains('alertaDiasSemTreinoHint'));
    expect(screen, contains('alertaAderenciaValue'));
    expect(screen, contains('AlertaDetalheSituacao'));
    expect(screen, contains('alertaMotivosVisiveis'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('/alunos/\${widget.alunoId}/chat'));
    expect(screen, contains('/alunos/\$alunoId'));
    expect(screen, contains('/financeiro?alunoId='));
    expect(screen, isNot(contains('alunoEmail')));
    expect(screen, isNot(contains('LinearProgressIndicator')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('Icons.refresh')));
  });
}
