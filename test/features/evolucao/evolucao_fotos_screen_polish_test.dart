import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('evolucao fotos cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/evolucao/screens/evolucao_fotos_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('listarFotosPagina'));
    expect(screen, contains('SliverGrid'));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('FilledButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
