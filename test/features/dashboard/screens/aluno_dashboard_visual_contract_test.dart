import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_source_bundle.dart';

void main() {
  test('Home "Hoje": um P0, ordem das perguntas e fold antigo fora', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    );
    int at(String s) {
      final i = screen.indexOf(s);
      expect(i, isNonNegative, reason: s);
      return i;
    }

    expect('emphasize: true'.allMatches(screen), hasLength(1));
    expect(at('AlunoHomeHeader('), lessThan(at('_TodayFocusCard(')));
    expect(at('_TodayFocusCard('), lessThan(at('_AlunoHomeAviso(')));
    expect(at('_AlunoHomeAviso('), lessThan(at('AlunoWeekSummaryCard(')));
    expect(at('AlunoWeekSummaryCard('), lessThan(at('AlunoRecoveryCard(')));
    expect(at('AlunoRecoveryCard('), lessThan(at('AlunoEvolutionCard(')));
    expect(at('AlunoEvolutionCard('), lessThan(at('AlunoPendenciasBlock(')));
    expect(at('AlunoPendenciasBlock('), lessThan(at('AlunoUpsellCarousel(')));
    expect(
      at('AlunoUpsellCarousel('),
      lessThan(at('_StudentToolsSection(atalhos: view.atalhos)')),
    );
    expect(screen, contains('insight: view.insight'));
    expect(screen, contains('view.semanaVisivel'));
    expect(screen, contains('view.prontidaoVisivel'));

    expect(screen, contains('s.alunoHomeTitulo'));
    expect(screen, contains('S.of(context).alunoHomePerfilSemantics'));
    expect(screen, contains('listenManual'));
    expect(screen, isNot(contains("'Meu Treino'")));
    expect(screen, isNot(contains('buildAlunoHomeExperience')));
    expect(screen, isNot(contains('rhythmLabel')));
    expect(screen, isNot(contains('_AlunoHeroCard')));
    expect(screen, isNot(contains('_StudentJourneyCard')));
    expect(screen, isNot(contains('_StreakFoldBadge')));
    expect(screen, isNot(contains('ProgressoSemanalWidget')));
    expect(screen, isNot(contains('Treinar agora')));
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
    expect(screen, contains('alunoConsistenciaCaption'));
    expect(screen, contains('alunoWeeklyDayGoal'));
    expect(screen, isNot(contains('clamp(3, 6)')));
    expect(screen, isNot(contains('de \$weeklyGoal dias')));
    expect(screen, isNot(contains('LinearProgressIndicator')));
    expect(screen, isNot(contains('Frequência')));
    expect(screen, contains('FocuxHubTypography.sectionTitle'));
    expect(screen, contains('FocuxHubTypography.bodyMuted'));
    expect(screen, contains('FocuxHubTypography.chip'));
    expect(screen, isNot(contains('FocuxHubTypography.metric')));
    expect(screen, isNot(contains('local_fire_department')));
    expect(screen, isNot(contains('BrandPalette.deep')));
    expect(screen, isNot(contains('LinearGradient')));
    expect(screen, isNot(contains('fontSize: 12')));
    expect(screen, isNot(contains('TextStyle(')));
    expect(screen, isNot(contains('cs.tertiary')));
    expect(screen, isNot(contains('EagleTokens.good')));
  });

  test('student profile copy keeps Portuguese accents', () {
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

    expect(hub, contains('Editar cadastro'));
    expect(hubBody, contains('Anamnese'));
    expect(profile, contains('foto de evolução'));
    expect(profile, contains('friendlyError'));
    expect(profile, contains('segurança e aderência'));
  });
}
