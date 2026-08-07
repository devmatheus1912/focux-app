import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('resetar senha cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/resetar_senha_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));

    // Senha mínima alinhada ao cadastro (8 caracteres) em hint e validador.
    expect(screen, contains('_minPasswordLength = 8'));
    expect(screen, contains('PasswordStrengthMeter'));
    expect(screen, isNot(contains('Minimo 6 caracteres')));
    expect(screen, isNot(contains('minimo 6 caracteres')));

    // Paleta hero teal para título e corpo do texto.
    expect(screen, contains('heroTeal'));

    // Erro/sucesso anunciados por leitores de tela.
    expect(screen, contains('liveRegion: true'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('authLogoWidthFor'));
  });
}
