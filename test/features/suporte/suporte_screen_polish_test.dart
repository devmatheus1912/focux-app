import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('suporte cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/suporte/screens/suporte_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxShellAppBar'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, isNot(contains('_SupportHeader')));
    expect(screen, isNot(contains('Navigator.of(context).maybePop')));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('suporteEnviarTicketConfirmTitle'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
