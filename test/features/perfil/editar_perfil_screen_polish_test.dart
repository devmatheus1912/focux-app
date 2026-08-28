import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('editar perfil cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/editar_perfil_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains("'Salvando…'"));
    expect(screen, contains('Salvando alterações do perfil'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showEditarPerfilHelpSheet'));
    expect(screen, contains('ProductEvents.perfilUpdated'));
    expect(screen, contains('_canSubmit'));
    expect(screen, contains('invalidatePacotesCaches'));
    expect(screen, contains('ref.invalidate(perfilProvider)'));
    expect(screen, contains('_PerfilPhotoEditor'));
    expect(screen, contains('_PerfilFormField'));
    expect(screen, contains('FxInputDeco.insetGrouped'));
    expect(screen, isNot(contains('google_fonts')));
    expect(screen, isNot(contains('FocuxTypography')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(8));
  });
}
