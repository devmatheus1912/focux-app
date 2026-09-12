import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ferramentas hub cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/ferramentas/screens/ferramentas_hub_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('HubEmbedScope'));
    expect(screen, contains('buildFerramentasTabScreen'));
    expect(screen, contains('ferramentas_hub_aba'));
    expect(screen, contains('TabBar'));
    expect(screen, contains('TabBarView'));
    expect(screen, contains('ferramentasCatalogoProvider'));
    expect(screen, contains('ref.invalidate'));
    expect(screen, contains('Hub indisponível'));
  });
}
