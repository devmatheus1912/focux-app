import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('depoimento aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/depoimentos/screens/depoimento_aluno_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('listarMeus'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('Navigator.of(context).pop()')));
  });
}
