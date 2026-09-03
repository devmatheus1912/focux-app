import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_agenda_hoje_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_base_radar_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_finance_empty.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_action_chip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_activation_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_coach_banner.dart';

void main() {
  testWidgets('finance empty é tile inset, sem chip in-card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BFA5)),
        ),
        home: Scaffold(
          body: DashboardFinanceEmptyState(mes: 'agosto', onOpen: () {}),
        ),
      ),
    );

    expect(find.byType(DashboardHomeActionChip), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OperationalMetricTile), findsOneWidget);
    expect(find.textContaining('RECEBIDO'), findsOneWidget);
    expect(find.text('R\$ 0'), findsOneWidget);
    expect(find.text(DashboardMicrocopy.abrirFinanceiro), findsNothing);
  });

  testWidgets('agenda strip mostra até 3 compromissos', (tester) async {
    final items = [
      AgendamentoResumo(
        id: 1,
        nomeAluno: 'Ana',
        horario: '08:00',
        status: 'CONFIRMADO',
      ),
      AgendamentoResumo(
        id: 2,
        nomeAluno: 'Bruno',
        horario: '10:00',
        status: 'PENDENTE',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardAgendaHojeStrip(items: items),
        ),
      ),
    );

    expect(find.text(DashboardMicrocopy.agendaHoje), findsOneWidget);
    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.textContaining('Bruno'), findsOneWidget);
  });

  testWidgets('radar da base renderiza scores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardBaseRadarStrip(
            scores: [
              AlunoScoreResumo(
                alunoId: 1,
                alunoNome: 'Carla',
                score: 72,
                ritmo: 'ok',
                risco: 'Risco médio',
                proximaAcao: 'Enviar mensagem',
                narrativa: '',
                objetivo: '',
                acaoUrl: '/alunos/1',
                prioridade: 'P1',
                iaSugerida: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(DashboardMicrocopy.radarDaBase), findsOneWidget);
    expect(find.textContaining('Carla'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.textContaining('Risco médio'), findsOneWidget);
  });

  testWidgets('radar some com só pendência de cadastro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardBaseRadarStrip(
            scores: [
              AlunoScoreResumo(
                alunoId: 1,
                alunoNome: 'Nathalia',
                score: 40,
                ritmo: 'ok',
                risco: 'Risco alto',
                proximaAcao: 'Completar mapa corporal',
                narrativa: '',
                objetivo: '',
                acaoUrl: '/alunos/1',
                prioridade: 'P0',
                iaSugerida: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(DashboardMicrocopy.radarDaBase), findsNothing);
    expect(find.textContaining('Nathalia'), findsNothing);
  });

  testWidgets('radar mostra 2 no fold e Ver todos no overflow', (tester) async {
    AlunoScoreResumo retomar(int id, String nome) => AlunoScoreResumo(
      alunoId: id,
      alunoNome: nome,
      score: 50,
      ritmo: 'ok',
      risco: 'Risco alto',
      proximaAcao: 'Retomar treino com mensagem curta',
      narrativa: '',
      objetivo: '',
      acaoUrl: '/alunos/$id',
      prioridade: 'P0',
      iaSugerida: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardBaseRadarStrip(
            scores: [
              retomar(1, 'Ana'),
              retomar(2, 'Bruno'),
              retomar(3, 'Carla'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.textContaining('Bruno'), findsOneWidget);
    expect(find.textContaining('Carla'), findsNothing);
    expect(find.text(DashboardMicrocopy.radarVerTodos), findsOneWidget);

    await tester.tap(find.text(DashboardMicrocopy.radarVerTodos));
    await tester.pumpAndSettle();

    expect(find.textContaining('Carla'), findsWidgets);
  });

  testWidgets('coach banner dismissível', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardHomeCoachBanner(
            isDark: false,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text(DashboardMicrocopy.coachCatalogHint), findsOneWidget);
    await tester.tap(find.text(DashboardMicrocopy.coachEntendi));
    expect(dismissed, isTrue);
  });

  testWidgets('faixa de ativação cabe em uma linha 52 + barra 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF13C2C2)),
        ),
        home: const Scaffold(
          body: DashboardHomeActivationStrip(
            title: 'Sua ativação',
            subtitle: 'Complete seu perfil',
            trailingMetric: '1/7',
            progress: 0.14,
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Sua ativação'), findsOneWidget);
    expect(find.text('Complete seu perfil'), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final size = tester.getSize(find.byType(DashboardHomeActivationStrip));
    expect(size.height, lessThan(88));
  });
}

void _noop() {}
