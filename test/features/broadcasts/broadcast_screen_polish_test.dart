import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('broadcast cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/broadcasts/screens/broadcast_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('FxSettingsLayout'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains("icon: 'circle-check'")));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('_AudienceChip')));
    expect(screen, isNot(contains('_DesignField')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('DropdownButton')));
  });

  test('broadcast historico segue pele do Perfil', () {
    final historico = readScreenSourceBundle(
      'lib/features/broadcasts/screens/widgets/broadcast_historico.dart',
    );
    expect(historico, contains('FxSettingsGroup'));
    expect(historico, contains('FxSettingsTile'));
    expect(historico, contains('FxEmptyState'));
    expect(historico, isNot(contains('Icons.people_outline_rounded')));
    expect(historico, isNot(contains('FxLiquidPrimaryButton')));
  });
}
