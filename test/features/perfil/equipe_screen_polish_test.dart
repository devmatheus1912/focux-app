import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('equipe cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/equipe_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('equipeRbac'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/perfil'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('listar('));
    expect(screen, contains('page:'));
    // §38 / §39.3 — mutate equipe hide até RBAC P0
    expect(screen, isNot(contains('convidar')));
    expect(screen, isNot(contains('Convidar')));
    expect(screen, isNot(contains('showFxFormSheet')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('.put(')));
    expect(screen, isNot(contains('.delete(')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('onTap: () {}')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('context.pop()')));
  });

  test('equipe repository is read-only until RBAC P0', () {
    final repo = readScreenSourceBundle(
      'lib/features/perfil/data/equipe_repository.dart',
    );
    expect(repo, contains('/api/tenant/membros'));
    expect(repo, contains('listar'));
    expect(repo, isNot(contains('convidar')));
    expect(repo, isNot(contains('.post(')));
    expect(repo, isNot(contains('.put(')));
    expect(repo, isNot(contains('.delete(')));
  });
}
