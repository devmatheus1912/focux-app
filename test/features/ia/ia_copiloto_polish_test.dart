import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('copiloto usa polish: shell, semantics e barra fixa', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );
    final shellWidgets =
        File(
          'lib/features/ia/widgets/ia_copilot_shell_widgets.dart',
        ).readAsStringSync();
    final insightWidgets =
        File(
          'lib/features/ia/widgets/ia_copilot_insight_widgets.dart',
        ).readAsStringSync();

    final actionsPart =
        File(
          'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
        ).readAsStringSync();

    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxShellAppBar'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(shellWidgets, contains('IaCopilotResultActionBar'));
    expect(shellWidgets, contains('FxInsetPickerOption'));
    expect(actionsPart, contains('explicitChildNodes: true'));
    expect(shellWidgets, contains('Como funciona'));
    expect(screen, contains('não monta fichas de treino'));
    expect(actionsPart, contains('showFxHomeSheet'));
    expect(actionsPart, contains('FxHomeSheetSurface'));
    expect(actionsPart, isNot(contains('showModalBottomSheet')));
    expect(actionsPart, isNot(contains('DraggableScrollableSheet')));
    expect(actionsPart, contains('Semantics('));
    expect(screen, isNot(contains('rascunho editável')));
    expect(insightWidgets, contains('IaCopilotInsight'));
    expect(insightWidgets, contains('insight.detalhe'));
    expect(screen, isNot(contains('Ações do rascunho')));
    expect(actionsPart, contains('Ações das recomendações'));
  });
}
