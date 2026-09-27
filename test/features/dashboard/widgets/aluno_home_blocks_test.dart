import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_autonomy_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_header.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_skeleton.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_pendencias_block.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_week_summary_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
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
      expect(find.bySemanticsLabel('Abrir conversa com Carlos'), findsOneWidget);
      await tester.tap(find.text('Seu personal: Carlos'));
      expect(abriu, isTrue);
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
        AlunoPendenciasBlock(pendencias: const [], onTap: (_) {}),
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

      expect(
        AlunoAutonomyAnalytics.completeResolved(repo, {'agenda-semana'}),
        ['foto-dados'],
      );
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
