import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('grupo aulas personal cumpre contrato Tier S+', () {
    // A folha de criar/editar mora em widgets/; o contrato vale para as duas.
    final screen = [
      readScreenSourceBundle(
        'lib/features/grupos/screens/grupo_aulas_personal_screen.dart',
      ),
      readScreenSourceBundle(
        'lib/features/grupos/widgets/grupo_aula_form_sheet.dart',
      ),
    ].join('\n');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('showFxCalendarioSheet'));
    expect(screen, contains('showTimePicker'));
    expect(screen, isNot(contains('showDatePicker')));
    // Um "Nova aula" só: o do rodapé fixo (o vazio não repete o botão).
    expect(screen, isNot(contains("FxEmptyAction(label: 'Nova aula'")));
    expect(
      File('lib/features/grupos/widgets/grupo_aula_form_sheet.dart').readAsStringSync(),
      contains('showFxCalendarioSheet'),
    );
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, contains('listarPersonalPagina'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('chip: _chip'));
    expect(screen, contains('_clearFilters'));
  });
}
