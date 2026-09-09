import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('exercicios list cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/exercicios_list_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('safePopOrGo(context, \'/treinos\')'));
  });

  test('exercicios list rows são S4 satellite', () {
    final list = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/exercicios_list_view.dart',
    );
    expect(list, contains('ListView.builder'));
    expect(list, contains('keyboardDismissBehavior'));
    expect(list, isNot(contains('FxSettingsGroup')));
    expect(list, contains('ExercicioCard'));
  });

  test('exercicios filter bar segue pele do Perfil', () {
    final bar = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/exercicios_filter_bar.dart',
    );
    expect(bar, contains('FxToggleChip'));
    expect(bar, contains('TextField'));
    expect(bar, isNot(contains('FxSettingsGroup')));
    expect(bar, isNot(contains('FxSettingsTile')));
    expect(bar, isNot(contains('FilterChip')));
    expect(bar, isNot(contains('ActionChip')));
    expect(bar, isNot(contains('PopupMenuButton')));
    expect(bar, isNot(contains('InputChip')));
  });

  test('exercicios filter sheet segue pele do Perfil', () {
    final sheet = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/exercicios_filter_sheet.dart',
    );
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('FxSettingsTile'));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('picker: true'));
    expect(sheet, contains('OutlinedButton'));
    expect(sheet, isNot(contains('FilterChip')));
    expect(sheet, isNot(contains('FxToggleChip')));
    expect(sheet, contains('Switch.adaptive'));
    expect(sheet, isNot(contains("label: exerciciosLimparFiltros()")));
  });
}
