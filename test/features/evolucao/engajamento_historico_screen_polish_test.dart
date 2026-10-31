import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('histórico da aderência cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/evolucao/screens/engajamento_historico_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('ListView.builder'));
  });
}
