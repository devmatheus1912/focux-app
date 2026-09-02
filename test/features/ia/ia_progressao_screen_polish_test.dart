import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ia progressao cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_progressao_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('IaProgressaoLoadingSkeleton'));
    expect(screen, contains('_loading'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'spark'"));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('IaSafetyDisclaimer'));
    expect(screen, contains('IaProgressaoResultView'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('person_add')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
