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

    final foco =
        File(
          'lib/features/dashboard/widgets/aluno_today_focus_card.dart',
        ).readAsStringSync();
    expect('emphasize: true'.allMatches(screen), isEmpty);
    expect('emphasize: true'.allMatches(foco), hasLength(1));
    expect(at('AlunoHomeHeader('), lessThan(at('AlunoTodayFocusCard(')));
    expect(at('AlunoTodayFocusCard('), lessThan(at('_AlunoHomeAviso(')));
    expect(at('_AlunoHomeAviso('), lessThan(at('AlunoPendenciasBlock(')));
    expect(at('AlunoPendenciasBlock('), lessThan(at('AlunoWeekSummaryCard(')));
    expect(at('AlunoWeekSummaryCard('), lessThan(at('AlunoRecoveryCard(')));
    expect(at('AlunoRecoveryCard('), lessThan(at('AlunoEvolutionCard(')));
    expect(at('AlunoEvolutionCard('), lessThan(at('AlunoUpsellCarousel(')));
    expect(at('AlunoUpsellCarousel('), lessThan(at('_StudentToolsSection(')));
    expect(screen, contains('mostrarDica: !view.prontidaoBaixa'));
    expect(screen, contains('horario: view.horarioNoFoco'));
    expect(screen, contains('if (featured.isNotEmpty)'));
    expect(screen, isNot(contains('volumePorSemana')));
    expect(
      screen,
      contains('recursosIndisponiveis: view.recursosIndisponiveis'),
    );
    expect(screen, contains('coachMensagens: view.coach'));
    expect(screen, contains('insight: view.insight'));
    expect(screen, contains('view.semanaVisivel'));
    expect(screen, contains('view.prontidaoVisivel'));

    expect(screen, contains('s.alunoHomeTitulo'));
    expect(screen, isNot(contains('_AlunoAppBarAvatar')));
    expect(
      foco,
      contains('AlunoHomeInsightLine(insight: insight, onPrimary: mute)'),
    );
    expect(screen, contains('listenManual'));
    expect(screen, isNot(contains("'Meu Treino'")));
    expect(screen, isNot(contains('buildAlunoHomeExperience')));
    expect(screen, isNot(contains('rhythmLabel')));
    expect(screen, isNot(contains('_AlunoHeroCard')));
    expect(screen, isNot(contains('_StudentJourneyCard')));
    expect(screen, isNot(contains('_StreakFoldBadge')));
    expect(screen, isNot(contains('ProgressoSemanalWidget')));
    expect(screen, isNot(contains('Treinar agora')));
    expect(screen, contains('prontidaoBaixa: view.prontidaoBaixa'));
    expect(screen, contains('onFinanceiro: _openFinanceiro'));
  });

  test('oferta da Home confirma antes de responder e não disputa com o P0', () {
    final carousel =
        File(
          'lib/features/monetizacao/widgets/aluno_upsell_carousel.dart',
        ).readAsStringSync();
    expect(carousel, contains('showFxConfirmSheet('));
    expect(carousel, contains('s.alunoOfertaAceitarConfirmTitulo'));
    expect(carousel, contains('s.alunoOfertaRecusarConfirmTitulo'));
    expect(carousel, isNot(contains('FilledButton')));
    expect(carousel, contains('.read(upsellRepositoryProvider)'));
    expect(carousel, isNot(contains('UpsellRepository(')));
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
