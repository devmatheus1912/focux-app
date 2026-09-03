import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('add lead cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/add_lead_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains("child: const Text('Cancelar')"));
    expect(screen, contains('enabled: _canSubmit'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains("icon: 'circle-check'")));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, isNot(contains('person_add')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
