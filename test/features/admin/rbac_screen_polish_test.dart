import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('rbac cumpre contrato S2', () {
    final screen = readScreenSourceBundle(
      'lib/features/admin/screens/rbac_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, isNot(contains('fxListTileCardShell')));
    expect(screen, isNot(contains('IconButton(\n                        icon: const Icon(\n                          Icons.delete_outline')));
    expect(screen, anyOf(contains('friendlyError'), contains('FxErrorState')));
    expect(screen, contains('SkeletonList'));
  });
}
