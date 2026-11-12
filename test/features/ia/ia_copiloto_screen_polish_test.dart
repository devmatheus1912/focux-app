import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ia copiloto cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
        contains('DashboardShimmer'),
        contains('Shimmer'),
        contains('IaCopilotGenerationStatus'),
        contains('_loading'),
      ),
    );
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('ia copiloto usa estados canônicos e mantém o disclaimer', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('CopilotoCardView'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('IaCopilotResultActionBar'));
    expect(screen, contains('iaCopilotoViewed'));
    expect(screen, contains('iaCopilotoHelpOpened'));
    expect(screen, contains('iaCopilotoHomeProvider'));
    expect(screen, contains("retryLabel:"));
    expect(screen, isNot(contains('OutlinedButton')));
    // Abre por cima (não é mais aba): o voltar do topo sai ou volta à abertura.
    // 12/11: voltar sempre (sem análise, volta para a Hoje).
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('keyboardDismissBehavior'));
  });
}
