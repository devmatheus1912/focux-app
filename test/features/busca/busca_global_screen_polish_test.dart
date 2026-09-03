import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('busca global cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/busca/screens/busca_global_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxSettingsLayout'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'x'"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('AlunoInsetFormField')));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('ChoiceChip')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Map<String, dynamic>')));
    expect(screen, isNot(contains('Icons.clear')));
    expect(screen, isNot(contains('Icons.person')));
  });

  test('busca global fold segue pele do Perfil', () {
    final results = readScreenSourceBundle(
      'lib/features/busca/screens/widgets/busca_global_results.dart',
    );
    expect(results, contains('FxSatelliteListTile'));
    expect(results, contains('DashboardSectionHeader'));
    expect(results, contains('FxEmptyState'));
    expect(results, isNot(contains('FxSettingsGroup')));
    expect(results, isNot(contains('FilterChip')));
    expect(results, isNot(contains('CircleAvatar')));
    expect(results, isNot(contains('Icons.person')));
    expect(results, isNot(contains('Map<String, dynamic>')));
  });
}
