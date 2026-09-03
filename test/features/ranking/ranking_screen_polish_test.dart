import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ranking cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/ranking/screens/ranking_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('Pódio do Mês')));
    expect(screen, contains('Buscar personal'));
    expect(screen, contains('onTapOutside'));
  });
}
