import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copiloto usa polish: shell, semantics e barra fixa', () {
    final screen =
        File('lib/features/ia/screens/ia_copiloto_screen.dart').readAsStringSync();
    final shellWidgets =
        File('lib/features/ia/widgets/ia_copilot_shell_widgets.dart').readAsStringSync();
    final insightWidgets =
        File('lib/features/ia/widgets/ia_copilot_insight_widgets.dart').readAsStringSync();

    final actionsPart =
        File('lib/features/ia/screens/ia_copiloto_screen_actions.part.dart')
            .readAsStringSync();

    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxShellAppBar'));
    expect(shellWidgets, contains('IaCopilotResultActionBar'));
    expect(actionsPart, contains('explicitChildNodes: true'));
    expect(shellWidgets, contains('Como funciona'));
    expect(screen, contains('não monta fichas de treino'));
    expect(actionsPart, contains('useSafeArea: true'));
    expect(actionsPart, contains('Semantics('));
    expect(screen, isNot(contains('rascunho editável')));
    expect(insightWidgets, contains('copilot_insight_text.dart'));
    expect(insightWidgets, contains('copilotInsightDetalhe'));
    expect(screen, isNot(contains('Ações do rascunho')));
    expect(actionsPart, contains('Ações das recomendações'));
  });
}
