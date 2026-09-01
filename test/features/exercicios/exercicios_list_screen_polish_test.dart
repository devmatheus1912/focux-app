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
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
  });

  test('exercicios filter bar segue pele do Perfil', () {
    final bar = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/exercicios_filter_bar.dart',
    );
    expect(bar, contains('FxSettingsGroup'));
    expect(bar, contains('FxSettingsTile'));
    expect(bar, contains('AlunoInsetFormField'));
    expect(bar, isNot(contains('FilterChip')));
    expect(bar, isNot(contains('ActionChip')));
    expect(bar, isNot(contains('PopupMenuButton')));
    expect(bar, isNot(contains('Chip(')));
  });

  test('exercicios filter sheet segue pele do Perfil', () {
    final sheet = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/exercicios_filter_sheet.dart',
    );
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('FxSettingsTile'));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, isNot(contains('FilterChip')));
    expect(sheet, isNot(contains('FxToggleChip')));
  });
}
