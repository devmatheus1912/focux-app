import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_pulse_strip.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _pulse({required int riscoAlto}) {
  return MaterialApp(
    home: Scaffold(
      body: DashboardDayPulseStrip(
        fade: const AlwaysStoppedAnimation(1),
        isDark: false,
        alunosAtivos: 5,
        checkinsHoje: 2,
        checkinsTrend: const [],
        riscoAlto: riscoAlto,
        primary: const Color(0xFF12A3A3),
        onAtivos: () {},
        onCheckins: () {},
        onRisco: () {},
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('risco zero mostra "Nenhum aluno em risco"', (tester) async {
    await tester.pumpWidget(_pulse(riscoAlto: 0));
    await tester.pump();

    expect(find.text('RISCO DE ABANDONO'), findsOneWidget);
    expect(find.text('Nenhum aluno em risco'), findsOneWidget);
    expect(find.text('Sem movimento hoje'), findsNothing);
  });

  testWidgets('risco com alunos pede contato', (tester) async {
    await tester.pumpWidget(_pulse(riscoAlto: 2));
    await tester.pump();

    expect(find.text('Alunos pedem contato'), findsOneWidget);
    expect(find.text('Nenhum aluno em risco'), findsNothing);
  });
}
