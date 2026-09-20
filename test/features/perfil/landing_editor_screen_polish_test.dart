import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('landing studio cumpre contrato Tier S+ de formulário', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/landing_editor_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxInputDeco'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('Entrevista'));
    expect(screen, contains('FloatingLabelBehavior.always'));
    expect(screen, contains('minLines: 2'));
    expect(screen, contains('maxLines: 6'));
  });
}
