import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('meus treinos cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/meus_treinos_screen.dart',
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
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
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
        contains('IaCopilotInsightsLoading'),
        contains('_loading'),
      ),
    );
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('showBack: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('meusTreinosPagina'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('_hasMore'));
    expect(screen, contains('treinosOrdenadosStartFirst'));
    expect(screen, contains('startableCount'));
    expect(screen, contains('ProgressoSemanalWidget'));
    expect(screen, contains('_WeekProgressStrip'));
    expect(screen, contains('Fiz o treino'));
    expect(screen, contains('TextButton'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('showPrimaryStart'));
    expect(screen, contains("label: 'Iniciar'"));
    expect(screen, contains("child: const Text('Ver status')"));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, contains('Pronto para treinar'));
    expect(screen, contains('confirmarPlano'));
    expect(screen, contains('alunoDashboardHomeProvider'));
    expect(screen, contains('ProgressoSemanalWidget'));
    expect(screen, contains('_WeekProgressStrip'));
    expect(screen, contains('_RetomarTreinoBanner'));
    expect(screen, contains('treinoSessaoEmAndamento'));
    expect(screen, isNot(contains('sem. de sequência')));
    expect(screen, contains('historicoCheckinProvider'));
    expect(screen, contains('MeusTreinosMemCache.clear'));
    expect(screen, contains('starting || confirming'));
    expect(screen, isNot(contains('_TrainingScoreBadge')));
    expect(screen, isNot(contains('buildAlunoHomeExperience')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
