import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_autonomy_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_header.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_skeleton.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_proximos_passos.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_today_focus_card.dart';
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

  group('AlunoHomeSkeleton', () {
    testWidgets('lê como carregando, sem spinner', (tester) async {
      await _pump(tester, const AlunoHomeSkeleton());
      expect(find.bySemanticsLabel('Carregando o seu dia'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('AlunoProximosPassos', () {
    testWidgets('lista vazia não desenha nada', (tester) async {
      await _pump(
        tester,
        AlunoProximosPassos(
          pendencias: const [],
          hoje: DateTime(2026, 9, 27),
          onTap: (_) {},
        ),
      );
      expect(find.text('Próximos passos'), findsNothing);
    });

    testWidgets('mostra itens, avisa exibição e repassa o toque', (
      tester,
    ) async {
      final mostrados = <AlunoPendenciaTipo>[];
      AlunoPendencia? tocada;
      await _pump(
        tester,
        AlunoProximosPassos(
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

    testWidgets('cada passo traz o seu verbo e "Ver mais" mostra o resto', (
      tester,
    ) async {
      var verMais = 0;
      await _pump(
        tester,
        AlunoProximosPassos(
          pendencias: const [
            AlunoPendencia(AlunoPendenciaTipo.medida),
            AlunoPendencia(AlunoPendenciaTipo.perfil),
            AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: 2),
          ],
          resto: 2,
          onVerMais: () => verMais++,
          hoje: DateTime(2026, 9, 27),
          onTap: (_) {},
        ),
      );
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Completar'), findsOneWidget);
      expect(find.text('Responder'), findsOneWidget);
      expect(find.text('Ver mais (2)'), findsOneWidget);
      await tester.tap(find.text('Ver mais (2)'));
      expect(verMais, 1);
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
        AlunoProximosPassos(
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
      expect(find.text('Começar'), findsOneWidget);
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
