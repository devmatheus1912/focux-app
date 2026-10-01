import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/core/widgets/fx_rive_player.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_destaque_exercicio.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_autonomy_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_evolution_card.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_header.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_skeleton.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_pendencias_block.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_today_focus_card.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_week_summary_card.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/widgets/aluno_recovery_card.dart';
import 'package:focux_app/features/monetizacao/data/upsell_repository.dart';
import 'package:focux_app/features/monetizacao/widgets/aluno_upsell_carousel.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

/// Tela de 360 dp com o padding da Home. A fonte de teste do Flutter tem
/// glifos de 1 em, mais larga que a Inter: a escala aqui já é o pior caso.
Future<void> _pumpEstreito(
  WidgetTester tester,
  Widget child, {
  double escala = 2,
}) async {
  tester.view
    ..physicalSize = const Size(360, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await _pump(tester, Padding(padding: const EdgeInsets.all(16), child: child));
}

void _expectInteiro(WidgetTester tester, Finder texto) {
  expect(texto, findsOneWidget);
  expect(
    tester.renderObject<RenderParagraph>(texto).didExceedMaxLines,
    isFalse,
  );
}

void _expectNadaCortado(WidgetTester tester) {
  final cortados = [
    for (final p in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    ))
      if (p.didExceedMaxLines) p.text.toPlainText(),
  ];
  expect(cortados, isEmpty);
}

const _ritmoCaiu = AlunoHomeInsight(
  tipo: AlunoInsightTipo.ritmoCaiu,
  confianca: AlunoInsightConfianca.high,
  chave: 'insightRitmoCaiu',
  params: {'media': '3'},
  titulo: 'Seu ritmo caiu',
  mensagem: 'Nas 4 semanas anteriores, sua média era de 3 treinos por semana.',
);

class _EventoFake {
  final String taskId;
  final String action;
  final String taskTitle;
  final bool? done;
  const _EventoFake(this.taskId, this.action, this.taskTitle, this.done);
}

class _RepoFake extends Fake implements AlunoRepository {
  final eventos = <_EventoFake>[];

  @override
  Future<void> registrarEventoAutonomia({
    required String taskId,
    required String taskTitle,
    required String action,
    String? route,
    String? priority,
    bool? done,
    int? profileCompletion,
  }) async {
    eventos.add(_EventoFake(taskId, action, taskTitle, done));
  }
}

void main() {
  group('AlunoHomeHeader', () {
    testWidgets('saudação com primeiro nome e linha do personal', (
      tester,
    ) async {
      var abriu = false;
      await _pump(
        tester,
        AlunoHomeHeader(
          alunoNome: 'Ana Paula',
          nomePersonal: 'Carlos',
          onOpenChat: () => abriu = true,
        ),
      );
      expect(find.text('Olá, Ana'), findsOneWidget);
      expect(find.text('Seu personal: Carlos'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Abrir conversa com Carlos'),
        findsOneWidget,
      );
      await tester.tap(find.text('Seu personal: Carlos'));
      expect(abriu, isTrue);
    });

    testWidgets('nome longo do personal inteiro com fonte grande', (
      tester,
    ) async {
      await _pumpEstreito(
        tester,
        escala: 1.5,
        AlunoHomeHeader(
          alunoNome: 'Ana',
          nomePersonal: 'Carlos Eduardo',
          onOpenChat: () {},
        ),
      );
      _expectInteiro(tester, find.text('Seu personal: Carlos Eduardo'));
    });

    testWidgets('sem nome do personal a linha não aparece', (tester) async {
      await _pump(
        tester,
        AlunoHomeHeader(alunoNome: 'Ana', nomePersonal: ' ', onOpenChat: () {}),
      );
      expect(find.text('Olá, Ana'), findsOneWidget);
      expect(find.textContaining('Seu personal'), findsNothing);
    });
  });

  group('AlunoWeekSummaryCard', () {
    testWidgets('com meta mostra "2 de 3" e lê uma frase', (tester) async {
      await _pump(
        tester,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: 2,
            meta: 3,
            streakSemanas: 4,
            volumeKg: 3200,
          ),
        ),
      );
      expect(find.text('2 de 3'), findsOneWidget);
      expect(find.text('4 semanas'), findsOneWidget);
      expect(find.text('3.200 kg'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '2 de 3 treinos nesta semana, sequência de 4 semanas, volume de 3.200 kg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('meta superada mostra "6 treinos" e "META 2 BATIDA"', (
      tester,
    ) async {
      await _pump(
        tester,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: 6,
            meta: 2,
            streakSemanas: 1,
            volumeKg: 12445,
          ),
        ),
      );
      expect(find.text('6 treinos'), findsOneWidget);
      expect(find.text('META DE 2 TREINOS'), findsOneWidget);
      expect(find.text('6 de 2'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('sem meta mostra só o número de treinos', (tester) async {
      await _pump(
        tester,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: 2,
            meta: null,
            streakSemanas: 1,
            volumeKg: null,
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('VOLUME'), findsNothing);
    });

    testWidgets('sem dado de sessões mostra só sequência e volume', (
      tester,
    ) async {
      await _pump(
        tester,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: null,
            meta: null,
            streakSemanas: 2,
            volumeKg: 900,
          ),
        ),
      );
      expect(find.text('TREINOS NA SEMANA'), findsNothing);
      expect(find.text('SEQUÊNCIA'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
    });

    testWidgets('só a sequência não desenha a faixa', (tester) async {
      await _pump(
        tester,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: null,
            meta: null,
            streakSemanas: 3,
            volumeKg: null,
          ),
        ),
      );
      expect(find.text('Sua semana'), findsNothing);
    });
  });

  group('AlunoHomeSkeleton', () {
    testWidgets('lê como carregando, sem spinner', (tester) async {
      await _pump(tester, const AlunoHomeSkeleton());
      expect(find.bySemanticsLabel('Carregando o seu dia'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('AlunoPendenciasBlock', () {
    testWidgets('lista vazia não desenha nada', (tester) async {
      await _pump(
        tester,
        AlunoPendenciasBlock(
          pendencias: const [],
          hoje: DateTime(2026, 9, 27),
          onTap: (_) {},
        ),
      );
      expect(find.text('Pendências'), findsNothing);
    });

    testWidgets('mostra itens, avisa exibição e repassa o toque', (
      tester,
    ) async {
      final mostrados = <AlunoPendenciaTipo>[];
      AlunoPendencia? tocada;
      await _pump(
        tester,
        AlunoPendenciasBlock(
          pendencias: const [
            AlunoPendencia(AlunoPendenciaTipo.foto),
            AlunoPendencia(AlunoPendenciaTipo.agenda),
          ],
          hoje: DateTime(2026, 9, 27),
          onTap: (p) => tocada = p,
          onShown: (p) => mostrados.add(p.tipo),
        ),
      );
      expect(find.text('Adicionar foto'), findsOneWidget);
      expect(find.text('Seu próximo horário'), findsOneWidget);
      expect(mostrados, [AlunoPendenciaTipo.foto, AlunoPendenciaTipo.agenda]);
      await tester.tap(find.text('Seu próximo horário'));
      expect(tocada?.tipo, AlunoPendenciaTipo.agenda);
    });

    testWidgets('hora do horário cabe com fonte 2x em tela estreita', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        AlunoPendenciasBlock(
          pendencias: [
            AlunoPendencia(
              AlunoPendenciaTipo.agenda,
              quando: DateTime(2026, 9, 30, 18),
            ),
          ],
          hoje: DateTime(2026, 9, 27),
          onTap: (_) {},
        ),
      );
      for (final texto in [
        find.text('Seu próximo horário'),
        find.textContaining('18:00'),
      ]) {
        expect(
          tester.renderObject<RenderParagraph>(texto).didExceedMaxLines,
          isFalse,
        );
      }
    });
  });

  group('AlunoTodayFocusCard', () {
    testWidgets('prazo, horário e prontidão aparecem com fonte 2x', (
      tester,
    ) async {
      await _pumpEstreito(
        tester,
        AlunoTodayFocusCard(
          action: AlunoTodayAction(
            mode: AlunoTodayMode.workoutReady,
            route: '/checkin/executar',
            treinoNome: 'Treino A',
            exerciseCount: 6,
            prazoFim: DateTime(2026, 9, 27),
          ),
          hoje: DateTime(2026, 9, 27, 8),
          horario: DateTime(2026, 9, 27, 18),
          prontidaoBaixa: true,
          isDark: false,
          onAction: () {},
        ),
      );
      _expectInteiro(tester, find.text('Vence hoje'));
      _expectInteiro(
        tester,
        find.text('Horário com seu personal: hoje às 18:00'),
      );
      _expectInteiro(
        tester,
        find.text(
          'Corpo pedindo descanso: se treinar, vá leve ou faça mobilidade.',
        ),
      );
      expect(find.text('Treinar agora'), findsOneWidget);
    });

    testWidgets('descrição longa e insight inteiros com fonte 2x', (
      tester,
    ) async {
      await _pumpEstreito(
        tester,
        AlunoTodayFocusCard(
          action: const AlunoTodayAction(
            mode: AlunoTodayMode.noWorkout,
            route: '/chat/aluno',
          ),
          hoje: DateTime(2026, 9, 27, 8),
          insight: _ritmoCaiu,
          isDark: false,
          onAction: () {},
        ),
      );
      _expectInteiro(
        tester,
        find.text(
          'Nenhum treino liberado agora. Seu personal libera o próximo pelo chat.',
        ),
      );
      _expectInteiro(tester, find.text('Seu ritmo caiu'));
      _expectInteiro(tester, find.text('Falar com o personal'));
      _expectInteiro(
        tester,
        find.text(
          'Nas 4 semanas anteriores, sua média era de 3 treinos por semana.',
        ),
      );
    });

    testWidgets('sem prazo nem horário as linhas somem', (tester) async {
      await _pump(
        tester,
        AlunoTodayFocusCard(
          action: const AlunoTodayAction(
            mode: AlunoTodayMode.workoutReady,
            route: '/checkin/executar',
            treinoNome: 'Treino A',
            exerciseCount: 6,
          ),
          hoje: DateTime(2026, 9, 27, 8),
          isDark: false,
          onAction: () {},
        ),
      );
      expect(find.textContaining('Vence'), findsNothing);
      expect(find.textContaining('Horário com seu personal'), findsNothing);
    });
  });

  group('AlunoEvolutionCard', () {
    const supino = AlunoDestaqueExercicio(
      nome: 'supino reto',
      serieSemanal: [40, 45, 50],
      inicialKg: 40,
      atualKg: 50,
      deltaPercent: 25,
      semanas: 6,
    );

    testWidgets('3+ semanas: de → até, ganho e curva do exercício', (
      tester,
    ) async {
      await _pump(tester, const AlunoEvolutionCard(destaque: supino));
      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('40 → 50 kg'), findsOneWidget);
      expect(find.text('1RM estimado'), findsOneWidget);
      expect(find.text('+25% em 6 semanas'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Gráfico de 6 semanas: 1RM estimado de supino reto, de 40 a 50 kg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('queda aparece com sinal, sem esconder', (tester) async {
      await _pump(
        tester,
        const AlunoEvolutionCard(
          destaque: AlunoDestaqueExercicio(
            nome: 'Supino reto',
            serieSemanal: [60, 55, 50],
            inicialKg: 60,
            atualKg: 50,
            deltaPercent: -16.7,
            semanas: 3,
          ),
        ),
      );
      expect(find.text('-16,7% em 3 semanas'), findsOneWidget);
    });

    testWidgets('1–2 semanas: carga atual e aviso da curva', (tester) async {
      await _pump(
        tester,
        const AlunoEvolutionCard(
          destaque: AlunoDestaqueExercicio(
            nome: 'Supino reto',
            serieSemanal: [45, 50],
            inicialKg: 45,
            atualKg: 50,
            deltaPercent: 11.1,
            semanas: 2,
          ),
        ),
      );
      expect(find.text('50 kg'), findsOneWidget);
      expect(
        find.text('Sua curva aparece a partir da 3ª semana de treino.'),
        findsOneWidget,
      );
      expect(find.textContaining('→'), findsNothing);
    });

    testWidgets('sem destaque: estado vazio', (tester) async {
      await _pump(tester, const AlunoEvolutionCard());
      expect(
        find.text('Registre a carga das séries para ver sua evolução aqui.'),
        findsOneWidget,
      );
    });

    RecordePessoal recorde(String data) => RecordePessoal(
      id: 1,
      exercicioId: 1,
      exercicioNome: 'Supino',
      data: data,
      cargaKg: 50,
    );

    testWidgets('rodapé conta os recordes do mês', (tester) async {
      await _pump(
        tester,
        AlunoEvolutionCard(
          destaque: supino,
          ultimoRecorde: recorde('2026-09-24'),
          recordesMes: 2,
        ),
      );
      expect(
        find.text('2 recordes este mês · último em 24/09'),
        findsOneWidget,
      );
    });

    testWidgets('rodapé no singular e sem recorde no mês', (tester) async {
      await _pump(
        tester,
        AlunoEvolutionCard(
          ultimoRecorde: recorde('2026-09-24'),
          recordesMes: 1,
        ),
      );
      expect(find.text('1 recorde este mês · último em 24/09'), findsOneWidget);

      await _pump(
        tester,
        AlunoEvolutionCard(ultimoRecorde: recorde('2026-08-02')),
      );
      expect(find.text('Último recorde em 02/08'), findsOneWidget);
    });

    testWidgets('nome longo não corta com fonte grande', (tester) async {
      await _pumpEstreito(
        tester,
        escala: 1.5,
        AlunoEvolutionCard(
          destaque: const AlunoDestaqueExercicio(
            nome: 'Agachamento livre com barra',
            serieSemanal: [80, 90, 100],
            inicialKg: 80,
            atualKg: 100,
            deltaPercent: 25,
            semanas: 3,
          ),
          ultimoRecorde: recorde('2026-09-24'),
          recordesMes: 3,
        ),
      );
      _expectNadaCortado(tester);
    });
  });

  group('AlunoWeekSummaryCard com fonte grande', () {
    test('empilha os tiles só acima de 1,3x', () {
      expect(alunoSemanaEmpilhada(const TextScaler.linear(1.3)), isFalse);
      expect(alunoSemanaEmpilhada(const TextScaler.linear(1.5)), isTrue);
    });

    testWidgets('empilhado, nenhum valor é cortado', (tester) async {
      await _pumpEstreito(
        tester,
        escala: 1.5,
        const AlunoWeekSummaryCard(
          summary: AlunoWeekSummary(
            feitos: 2,
            meta: 3,
            streakSemanas: 4,
            volumeKg: 3200,
          ),
        ),
      );
      _expectNadaCortado(tester);
      expect(find.text('4 semanas'), findsOneWidget);
      expect(find.text('3.200 kg'), findsOneWidget);
    });
  });

  group('AlunoRecoveryCard', () {
    const baixa = RecoverySnapshot(
      steps: 0,
      caloriesBurned: 0,
      avgHeartRate: 0,
      sleepHours: 0,
      recoveryScore: 40,
      recoveryLabel: 'Descanso recomendado',
      recoveryHint: 'Sono ou carga baixa',
    );

    testWidgets('sem a dica quando o foco já falou', (tester) async {
      await _pump(
        tester,
        const AlunoRecoveryCard(snapshot: baixa, mostrarDica: false),
      );
      expect(find.text('Descanso recomendado'), findsOneWidget);
      expect(find.text('Sono ou carga baixa'), findsNothing);
      expect(
        find.bySemanticsLabel('Prontidão 40 de 100. Descanso recomendado.'),
        findsOneWidget,
      );
    });

    testWidgets('sem nota do servidor: -- e sem conselho de ir mais leve', (
      tester,
    ) async {
      const semNota = RecoverySnapshot(
        steps: 0,
        caloriesBurned: 0,
        avgHeartRate: 0,
        sleepHours: 0,
        recoveryScore: null,
        recoveryLabel: '',
        recoveryHint: '',
      );
      final baixa = alunoProntidaoBaixa(
        mode: AlunoTodayMode.workoutReady,
        snapshot: semNota,
        prontidaoVisivel: true,
      );
      await _pump(
        tester,
        Column(
          children: [
            AlunoTodayFocusCard(
              action: const AlunoTodayAction(
                mode: AlunoTodayMode.workoutReady,
                route: '/checkin/executar',
                treinoNome: 'Treino A',
                exerciseCount: 6,
              ),
              hoje: DateTime(2026, 9, 28, 8),
              prontidaoBaixa: baixa,
              isDark: false,
              onAction: () {},
            ),
            AlunoRecoveryCard(snapshot: semNota, mostrarDica: !baixa),
          ],
        ),
      );
      expect(baixa, isFalse);
      expect(find.text('--'), findsOneWidget);
      expect(find.textContaining('vá leve'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('dica inteira com fonte 2x', (tester) async {
      const hint =
          'Priorize mobilidade, sono e hidratação antes de intensificar.';
      await _pumpEstreito(
        tester,
        const AlunoRecoveryCard(
          snapshot: RecoverySnapshot(
            steps: 0,
            caloriesBurned: 0,
            avgHeartRate: 0,
            sleepHours: 0,
            recoveryScore: 50,
            recoveryLabel: 'Recuperação parcial',
            recoveryHint: hint,
          ),
        ),
      );
      _expectInteiro(tester, find.text(hint));
    });

    testWidgets('movimento reduzido: sem animação em loop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: AlunoRecoveryCard(snapshot: baixa)),
          ),
        ),
      );
      expect(find.byType(FxRivePlayer), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });

  group('AlunoUpsellCarousel', () {
    testWidgets('título e descrição inteiros com fonte 2x', (tester) async {
      await _pumpEstreito(
        tester,
        ProviderScope(
          child: AlunoUpsellCarousel(
            ofertas: [
              AlunoOferta(
                alunoOfertaId: 1,
                ofertaId: 1,
                titulo: 'Consultoria extra',
                descricao: 'Uma sessão avulsa',
                valor: FxMoney.parse(150),
                status: 'PENDENTE',
              ),
            ],
          ),
        ),
      );
      _expectNadaCortado(tester);
    });
  });

  group('AlunoAutonomyAnalytics', () {
    setUp(AlunoAutonomyAnalytics.resetSessao);

    test('visto 1× por sessão por taskId; clique sempre manda', () {
      final repo = _RepoFake();
      final foto = AlunoAutonomyAnalytics.forPendencia(
        const AlunoPendencia(AlunoPendenciaTipo.foto),
      );
      expect(AlunoAutonomyAnalytics.viewed(repo, foto), isTrue);
      expect(AlunoAutonomyAnalytics.viewed(repo, foto), isFalse);
      AlunoAutonomyAnalytics.clicked(repo, foto);
      AlunoAutonomyAnalytics.clicked(repo, foto);
      expect(repo.eventos.map((e) => e.action), [
        'VIEWED',
        'CLICKED',
        'CLICKED',
      ]);
      expect(repo.eventos.first.taskId, 'foto-dados');
    });

    test('logout limpa os vistos', () {
      final repo = _RepoFake();
      final agenda = AlunoAutonomyAnalytics.forPendencia(
        const AlunoPendencia(AlunoPendenciaTipo.agenda),
      );
      AlunoAutonomyAnalytics.viewed(repo, agenda);
      SessionInvalidator.clearTenantMemoryCaches();
      expect(AlunoAutonomyAnalytics.viewed(repo, agenda), isTrue);
    });

    test('P0 só gera evento quando o personal precisa agir', () {
      AlunoTodayAction acao(AlunoTodayMode m) =>
          AlunoTodayAction(mode: m, route: '/x');
      expect(
        AlunoAutonomyAnalytics.forToday(acao(AlunoTodayMode.noWorkout))?.taskId,
        'treino-semana',
      );
      expect(AlunoAutonomyAnalytics.financeiro.taskId, 'financeiro');
      expect(AlunoAutonomyAnalytics.financeiro.route, '/financeiro/aluno');
      expect(
        alunoAutonomyOpenTaskIds(
          action: acao(AlunoTodayMode.workoutReady),
          pendenciasAbertas: const [],
          financeiroEmAtraso: true,
        ),
        {'financeiro'},
      );
      expect(
        AlunoAutonomyAnalytics.forToday(acao(AlunoTodayMode.workoutReady)),
        isNull,
      );
      expect(
        AlunoAutonomyAnalytics.forToday(acao(AlunoTodayMode.awaitingRelease)),
        isNull,
      );
    });

    test('fecha 1× o que foi tocado e saiu das abertas', () {
      final repo = _RepoFake();
      final foto = AlunoAutonomyAnalytics.forPendencia(
        const AlunoPendencia(AlunoPendenciaTipo.foto),
      );
      final agenda = AlunoAutonomyAnalytics.forPendencia(
        const AlunoPendencia(AlunoPendenciaTipo.agenda),
      );
      AlunoAutonomyAnalytics.clicked(repo, foto);
      AlunoAutonomyAnalytics.clicked(repo, agenda);
      repo.eventos.clear();

      expect(AlunoAutonomyAnalytics.completeResolved(repo, {'agenda-semana'}), [
        'foto-dados',
      ]);
      expect(
        AlunoAutonomyAnalytics.completeResolved(repo, {'agenda-semana'}),
        isEmpty,
      );
      expect(repo.eventos, hasLength(1));
      expect(repo.eventos.single.action, 'COMPLETED');
      expect(repo.eventos.single.taskId, 'foto-dados');
      expect(repo.eventos.single.done, isTrue);
    });

    test('só visto, sem toque, não vira COMPLETED', () {
      final repo = _RepoFake();
      AlunoAutonomyAnalytics.viewed(
        repo,
        AlunoAutonomyAnalytics.forPendencia(
          const AlunoPendencia(AlunoPendenciaTipo.chat),
        ),
      );
      expect(AlunoAutonomyAnalytics.completeResolved(repo, const {}), isEmpty);
    });

    test('logout esquece os toques', () {
      final repo = _RepoFake();
      AlunoAutonomyAnalytics.clicked(
        repo,
        AlunoAutonomyAnalytics.forPendencia(
          const AlunoPendencia(AlunoPendenciaTipo.foto),
        ),
      );
      SessionInvalidator.clearTenantMemoryCaches();
      expect(AlunoAutonomyAnalytics.completeResolved(repo, const {}), isEmpty);
    });

    test('abertas juntam o P0 e todas as pendências', () {
      expect(
        alunoAutonomyOpenTaskIds(
          action: const AlunoTodayAction(
            mode: AlunoTodayMode.noWorkout,
            route: '/chat/aluno',
          ),
          pendenciasAbertas: const [
            AlunoPendencia(AlunoPendenciaTipo.foto),
            AlunoPendencia(AlunoPendenciaTipo.agenda),
          ],
        ),
        {'treino-semana', 'foto-dados', 'agenda-semana'},
      );
      expect(
        alunoAutonomyOpenTaskIds(
          action: const AlunoTodayAction(
            mode: AlunoTodayMode.workoutReady,
            route: '/checkin',
          ),
          pendenciasAbertas: const [],
        ),
        isEmpty,
      );
    });
  });
}
