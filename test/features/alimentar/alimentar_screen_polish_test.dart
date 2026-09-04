import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alimentar cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alimentar/screens/alimentar_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showAlimentarHelpSheet'));
    expect(screen, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('_MacroBar'));
    expect(screen, contains('FxIcon'));
    expect(screen, contains('alimentarFxIcon'));
    expect(screen, contains("'/alunos/\${widget.alunoId}/alimentar/\${plano.id}'"));
    expect(screen, isNot(contains('Navigator.push')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('_NovoPlanoScreen')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect(screen, isNot(contains('Aluno #')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
