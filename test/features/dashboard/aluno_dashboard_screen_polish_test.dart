import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
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
    expect(screen, isNot(contains('FxEmptyState')));
    expect(screen, isNot(contains('minhaAnamneseProvider')));
    expect(screen, contains('AlunoHomeAnalytics.viewed'));
    expect(screen, contains('AlunoHomeAnalytics.focusAction'));
    expect(screen, contains('showAlunoNpsPrompt(context, ref)'));
    expect(screen, contains('currentConfiguration.uri.path == alunoHomeRoute'));
    expect(screen, contains('_router = router..addListener(_onRota)'));
    expect(screen, contains('skipError: true'));
    expect(screen, contains('refreshAlunoDashboardHome(ref)'));
    expect(screen, contains('s.alunoHomeAtualizarErro'));
    expect(screen, contains('AlunoTodayMode.workoutDone'));
    expect(screen, isNot(contains('invalidate(alunoRecoveryProvider)')));
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
    expect(screen, isNot(contains('SkeletonList')));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('useSafeArea: true')));
    expect(screen, contains('showBack: false'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('AlunoTodayFocusCard('));
    expect(screen, contains('AlunoWeekSummaryCard'));
    expect(screen, contains('AlunoEvolutionCard'));
    expect(screen, contains('AlunoPendenciasBlock'));
    expect(screen, isNot(contains('_StreakFoldBadge')));
    expect(screen, isNot(contains('Ver plano completo')));
    expect(screen, isNot(contains('Seu score Focux')));
    expect(screen, isNot(contains('RecoveryScoreRing')));
    expect(screen, contains('s.alunoAtalhosVerCatalogo'));
    expect(screen, contains('AlunoHomeSkeleton()'));
    expect(screen, contains('fxAnnounce('));
    expect(screen, contains('s.alunoHomeAjudaCalculo'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('s.alunoFerramentasSubtitulo'));
    expect(screen, isNot(contains('/ia/aluno')));
    expect(screen, isNot(contains('/aluno/form-check')));
    expect(screen, contains('/aluno/desafios'));
    expect(screen, contains('/aluno/trilhas'));
    expect(screen, contains('/aluno/grupo-aulas'));
    expect(screen, isNot(contains('/gamificacao')));
    expect(screen, isNot(contains('FxSatelliteListTile')));
    expect(screen, isNot(contains('class _AlunoProfileCard')));
  });

  test('Home do aluno fica certa no tempo e barata de redesenhar', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    );
    final provider =
        File(
          'lib/features/dashboard/providers/dashboard_provider.dart',
        ).readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(screen, contains('memo.\$3 == dia'));
    expect(screen, contains('_viewFor(home, now)'));
    expect(screen, contains('hoje: now'));
    expect(
      RegExp(
        r'subtitle: homeAsync\.when\(\s*skipLoadingOnReload: true,\s*skipError: true',
      ).hasMatch(screen),
      isTrue,
    );
    expect(
      screen,
      contains('if (atual != null && atual.inicio == inicio) return;'),
    );
    expect(provider, contains('AlunoDashboardHomeClientCache.revalidar()'));
    expect(main, contains('ref.invalidate(alunoDashboardHomeProvider);'));
  });
}
