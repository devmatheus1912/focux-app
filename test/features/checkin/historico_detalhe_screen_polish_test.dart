import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('historico detalhe cumpre contrato S3', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/historico_detalhe_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('historicoStickyLabel'));
    expect(screen, contains("safePopOrGo(context, '/checkin/historico')"));
    expect(screen, contains("'/checkin/executar'"));
    expect(screen, contains('detalhe(widget.execucaoId)'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FloatingActionButton')));
  });
}
