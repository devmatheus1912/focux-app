import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_source_bundle.dart';

void main() {
  test('student autonomy center keeps compact mobile layouts safe', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    );

    expect(screen, contains('class _NextBestTaskPanel'));
    expect(screen, contains('final compact = constraints.maxWidth < 390'));
    expect(screen, contains('SizedBox(width: double.infinity, child: action)'));
    expect(screen, contains('maxLines: 3'));
    expect(screen, contains('class _AutonomyTaskTile'));
    expect(screen, contains('final compact = constraints.maxWidth < 360'));
    expect(screen, contains('BoxConstraints(maxWidth: 180)'));
    expect(screen, contains('BoxConstraints(maxWidth: 132)'));
    expect(screen, contains('class _AlunoAppBarProfileMenu'));
    expect(screen, contains("label: 'Perfil do aluno'"));
    expect(screen, contains('class _WorkoutInsightPill'));
    expect(screen, contains('class _WorkoutInsightPill'));
    expect(screen, contains('buildAlunoHomeExperience'));
    expect(screen, contains('class _HomeNarrativeRail'));
    expect(screen, contains('Evolução do treino'));
    expect(screen, contains('streakAtual'));
    expect(screen, contains('_StreakFoldBadge'));
    expect(screen, contains('score.rhythmLabel'));
    expect(screen, isNot(contains('Seu score Focux')));
    expect(screen, isNot(contains('score.riskLabel')));
    expect(screen, contains('brand.nomePersonal'));
    expect(screen, contains("'Ativo'"));
    expect(screen, isNot(contains('class _StudentStatsRow')));
    expect(screen, contains("'Sem ação agora'"));
    expect(screen, contains("'Prioridade média'"));
    expect(screen, contains("'Conferir horário'"));
  });

  test('weekly progress card follows white label and accent copy', () {
    final screen =
        File(
          'lib/features/dashboard/screens/progresso_semanal_widget.dart',
        ).readAsStringSync();

    expect(screen, contains('FxStripCard'));
    expect(screen, contains("'Consistência'"));
    expect(screen, contains('descanso não zera'));
    expect(screen, contains('countUniqueCompletedDaysThisWeek'));
    expect(screen, contains('de \$weeklyGoal dias'));
    expect(screen, isNot(contains('Frequência')));
    expect(screen, contains('FocuxHubTypography.sectionTitle'));
    expect(screen, contains('FocuxHubTypography.bodyMuted'));
    expect(screen, contains('FocuxHubTypography.metric'));
    expect(screen, isNot(contains('local_fire_department')));
    expect(screen, isNot(contains('BrandPalette.deep')));
    expect(screen, isNot(contains('LinearGradient')));
    expect(screen, isNot(contains('fontSize: 12')));
    expect(screen, isNot(contains('TextStyle(')));
    expect(screen, isNot(contains('cs.tertiary')));
    expect(screen, isNot(contains('EagleTokens.good')));
  });

  test('student profile and autonomy copy keep Portuguese accents', () {
    final hub = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_screen.dart',
    );
    final hubBody =
        File(
          'lib/features/dashboard/widgets/perfil_aluno_hub_body.dart',
        ).readAsStringSync();
    final profile = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_editar_screen.dart',
    );
    final plan =
        File(
          'lib/features/dashboard/data/aluno_autonomy_plan.dart',
        ).readAsStringSync();

    expect(hub, contains('Editar cadastro'));
    expect(hubBody, contains('Anamnese'));
    expect(profile, contains('foto de evolução'));
    expect(profile, contains('friendlyError'));
    expect(profile, contains('segurança e aderência'));
    expect(plan, contains('histórico de carga, aderência'));
    expect(plan, contains('você está pronto'));
    expect(plan, contains('dúvidas, dor, dificuldade, preferência'));
    expect(plan, contains('horários, compromissos e presenças'));
    expect(plan, contains('pendências para não interromper'));
  });
}
