import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('equipe é superfície Em breve (fora de produção)', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/equipe_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('Equipe em breve'));
    expect(screen, contains('Em breve'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/perfil'));
    expect(screen, isNot(contains('SkeletonList')));
    expect(screen, isNot(contains('RefreshIndicator')));
    expect(screen, isNot(contains('FxToggleChip')));
    expect(screen, isNot(contains('listar(')));
    expect(screen, isNot(contains('convidar')));
    expect(screen, isNot(contains('Convidar')));
    expect(screen, isNot(contains('showFxFormSheet')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
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
