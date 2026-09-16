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
    expect(screen, contains("Text('Perfil')"));
    expect(screen, contains("Text('Sair')"));
    expect(screen, contains('class _WorkoutMetricPill'));
    expect(screen, contains('class _WorkoutInsightPill'));
    expect(screen, contains('buildAlunoHomeExperience'));
    expect(screen, contains('class _HomeNarrativeRail'));
    expect(screen, contains('Focux \${score.value}'));
    expect(screen, contains('score.rhythmLabel'));
    expect(screen, contains('score.riskLabel'));
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

    expect(screen, contains('BrandPalette.deep(cs.primary)'));
    expect(screen, contains("'Consistência'"));
    expect(screen, contains("'Treinos concluídos nesta semana'"));
    expect(screen, contains('TokensStrip.rCard'));
    expect(screen, isNot(contains('cs.tertiary')));
    expect(screen, isNot(contains('EagleTokens.good')));
  });

  test('student profile and autonomy copy keep Portuguese accents', () {
    final hub = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_screen.dart',
    );
    final profile = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_editar_screen.dart',
    );
    final plan =
        File(
          'lib/features/dashboard/data/aluno_autonomy_plan.dart',
        ).readAsStringSync();

    expect(hub, contains('Editar cadastro'));
    expect(hub, contains('Anamnese'));
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
