import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('gamificacao usa polish: provider, retry e tokens', () {
    final screen = readScreenSourceBundle(
      'lib/features/gamificacao/screens/gamificacao_screen.dart',
    );
    final provider = readScreenSourceBundle(
      'lib/features/gamificacao/providers/gamificacao_provider.dart',
    );

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('DashboardErrorState'));
    expect(screen, contains('gamificacaoProvider'));
    expect(screen, contains('EagleTokens.darkInk'));
    expect(screen, isNot(contains('Colors.white')));
    expect(provider, contains('gamificacaoProvider'));
    expect(provider, contains('GamificacaoRepository'));
    expect(screen, isNot(contains('final gamificacaoProvider')));
  });
}
