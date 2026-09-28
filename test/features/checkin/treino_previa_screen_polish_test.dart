import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prévia do treino cumpre contrato S3', () {
    final screen =
        File(
          'lib/features/checkin/screens/treino_previa_screen.dart',
        ).readAsStringSync();

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('treinoPreviaProvider(widget.treinoId)'));
    expect(screen, contains('treinoPreviaSituacao('));
    expect(screen, contains('treinoPreviaMostraJaFiz(situacao)'));
    expect(screen, contains("safePopOrGo(context, '/checkin/treinos')"));
    expect(screen, contains('context.pop(true)'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError(e)'));
    expect(screen, contains('invalidateAlunoDashboardHome(ref)'));
    expect(screen, isNot(contains('emphasize: true')));
    expect(screen, isNot(contains("showError(context, '\$e')")));
  });
}
