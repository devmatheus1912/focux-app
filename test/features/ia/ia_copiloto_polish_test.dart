import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copiloto usa polish 10/10: shell, semantics e barra fixa', () {
    final screen =
        File('lib/features/ia/screens/ia_copiloto_screen.dart').readAsStringSync();

    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxShellAppBar'));
    expect(screen, contains('_CopilotResultActionBar'));
    expect(screen, contains('explicitChildNodes: true'));
    expect(screen, contains('Como funciona'));
    expect(screen, contains('não monta fichas de treino'));
    expect(screen, contains('useSafeArea: true'));
    expect(screen, contains('Semantics('));
    expect(screen, isNot(contains('rascunho editável')));
    expect(screen, contains('copilot_insight_text.dart'));
    expect(screen, contains('copilotInsightDetalhe'));
    expect(screen, isNot(contains('Ações do rascunho')));
    expect(screen, contains('Ações das recomendações'));
  });
}
