import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_agenda_hoje_strip.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_activation_strip.dart';

void main() {
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

  testWidgets('faixa de ativação cabe em uma linha 52 + barra 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B4F5C)),
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
