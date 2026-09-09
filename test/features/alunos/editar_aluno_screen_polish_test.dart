import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('editar aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alunos/screens/editar_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains("child: const Text('Cancelar')"));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
