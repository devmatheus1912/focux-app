import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('pacotes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/pacotes/screens/pacotes_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('/financeiro'));
    expect(screen, contains('ListView.builder'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('context.pop()')));
  });

  test('novo plano usa form inset', () {
    final hub = readScreenSourceBundle(
      'lib/features/pacotes/widgets/pacotes_storefront_widgets.dart',
    );
    final sheet = readScreenSourceBundle(
      'lib/features/pacotes/widgets/novo_pacote_sheet.dart',
    );
    expect(sheet, contains('AlunoInsetFormField'));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('showFxConfirmSheet'));
    expect(sheet, contains('pacoteCriarConfirmTitle'));
    expect(sheet, contains('FxLiquidPrimaryButton'));
    expect(sheet, isNot(contains('ElevatedButton')));
    expect(sheet, contains('label: pacoteCriarTileLabel()'));
    expect(sheet, contains('Switch.adaptive'));
    expect(hub, isNot(contains('FxLiquidPrimaryButton')));
    expect(hub, contains('confirmDesativarPacote'));
    expect(sheet, isNot(contains('confirmDesativarPacote')));
    expect(hub, contains("child: const Text('Copiar link')"));
    expect(hub, isNot(contains("label: 'Copiar link'")));
    expect(sheet, isNot(contains('FxLiquidSecondaryButton')));
    expect(sheet, isNot(contains('ChoiceChip')));
    expect(sheet, isNot(contains('DropdownButton')));
  });
}
