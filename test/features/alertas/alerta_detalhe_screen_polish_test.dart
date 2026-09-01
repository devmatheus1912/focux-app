import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alerta detalhe cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alertas/screens/alerta_detalhe_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('IaSafetyDisclaimer'));
    expect(screen, contains('alertasDetalheViewed'));
    expect(screen, contains('Melhorar com IA'));
    expect(screen, contains('aplicarSugestaoIa'));
    expect(screen, contains('/alunos/\${widget.alunoId}/chat'));
    expect(screen, isNot(contains('alunoEmail')));
    expect(screen, isNot(contains('LinearProgressIndicator')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('Icons.refresh')));
  });
}
