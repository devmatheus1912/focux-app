import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('desafios aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/desafios/screens/desafios_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/aluno')"));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('desafioAlunoDetailPath'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('comunidadeGrupos'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('friendlyError'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FloatingActionButton')));
  });
}
