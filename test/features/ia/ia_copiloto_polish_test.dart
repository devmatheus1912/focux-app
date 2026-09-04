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
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(shellWidgets, contains('IaCopilotResultActionBar'));
    expect(shellWidgets, contains('DashboardHomeActionChip'));
    expect(
      'DashboardHomeActionChip'.allMatches(shellWidgets).length,
      2,
      reason: 'P0 só em Gerar + sticky de resultado — seletor de aluno é tonal',
    );
    expect(shellWidgets, contains('FxConversionTextLink'));
    expect(shellWidgets, contains('FxToggleChip'));
    expect(shellWidgets, contains('person_outline_rounded'));
    expect(shellWidgets, contains('Pronto para revisão'));
    expect(shellWidgets, isNot(contains('Recomendações prontas')));
    expect(shellWidgets, contains('chrome.cardFill'));
    expect(shellWidgets, isNot(contains('FxSettingsGroup')));
    expect(shellWidgets, isNot(contains('SafeArea(')));
    expect(shellWidgets, isNot(contains('scrollReserve')));
    expect(screen, contains('bottomNavigationBar:'));
    expect(screen, isNot(contains('IaCopilotResultActionBar.scrollReserve')));
    expect(screen, isNot(contains('bottom: _gerado ? 108')));
    expect(screen, contains('if (!_gerado)'));
    expect(screen, contains('IaCopilotReadinessCard'));
    expect(actionsPart, contains('explicitChildNodes: true'));
    expect(shellWidgets, contains('Como funciona'));
    expect(
      File('lib/features/ia/widgets/ia_copiloto_help_sheet.dart')
          .readAsStringSync(),
      contains('Como calculamos'),
    );
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
    expect(screen, contains('Ações das recomendações'));
    expect(screen, contains('showCopilotExecutarConfirmSheet'));
    expect(screen, contains('BrandPalette.softened'));
    expect(screen, isNot(contains('BrandPalette.soft(')));
    expect(screen, isNot(contains('BrandPalette.accent')));
    expect(screen, isNot(contains('BrandPalette.deep')));
    expect(actionsPart, contains('showIaCopilotCreateTaskSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('iaCopilotoGerarConfirmTitle'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(shellWidgets, isNot(contains('FxLiquidPrimaryButton')));
    expect(shellWidgets, isNot(contains('chevron_right')));
    expect(actionsPart, isNot(contains('chevron_right')));
    expect(shellWidgets, contains('IaCopilotPreviewCard'));
    expect(shellWidgets, contains('IaCopilotGenerationStatus'));
    expect(
      File(
        'lib/features/ia/widgets/ia_copilot_create_task_sheet.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxLiquidPrimaryButton'),
        contains('iaCopilotoCriarTarefaLabel'),
        contains('BrandPalette.softened'),
        isNot(contains('BrandPalette.accent')),
        isNot(contains('FxSettingsTile')),
      ),
    );
  });
}
