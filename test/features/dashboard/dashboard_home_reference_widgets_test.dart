import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_agenda_hoje_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_base_radar_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_finance_empty.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_coach_banner.dart';

void main() {
  testWidgets('finance empty CTA usa contraste AA (branco + tinta escura)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardFinanceEmptyState(
            mes: 'agosto',
            onOpen: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final style = button.style!;
    expect(
      style.backgroundColor!.resolve({}),
      Colors.white,
    );
    expect(
      style.foregroundColor!.resolve({}),
      const Color(0xFF0B1524),
    );
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
          body: DashboardAgendaHojeStrip(
            items: items,
            isDark: true,
            primary: const Color(0xFF00D4E8),
          ),
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
            isDark: true,
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
}
