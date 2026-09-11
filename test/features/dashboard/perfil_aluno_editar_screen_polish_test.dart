import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('perfil aluno editar cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_editar_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('Salvar meu perfil'));
    expect(screen, contains('friendlyError'));
    expect(screen, isNot(contains('DashboardHomeActionChip')));
    expect(
      screen,
      isNot(contains("child: const Text('Salvar')")),
    );
  });
}
