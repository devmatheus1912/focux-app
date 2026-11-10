import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('trilhas do aluno: mesmas peças do personal, sem cartões de número', () {
    final screen = readScreenSourceBundle(
      'lib/features/trilhas/screens/aluno_trilhas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('TrilhasLista'));
    expect(screen, contains('doPersonal: false'));
    expect(screen, contains('chatAlunoRascunhoProvider'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/aluno')"));
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('Ir aos treinos')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
