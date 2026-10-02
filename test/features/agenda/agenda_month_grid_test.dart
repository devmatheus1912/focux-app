import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_month.dart';
import 'package:focux_app/features/agenda/widgets/agenda_month_grid.dart';
import 'package:google_fonts/google_fonts.dart';

Agendamento _ag(int id, int hora, String nome) => Agendamento(
  id: id,
  alunoId: id,
  alunoNome: nome,
  inicio: DateTime(2026, 10, 7, hora),
  fim: DateTime(2026, 10, 7, hora + 1),
  status: 'AGENDADO',
);

Future<List<int>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final swipes = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AgendaMonthGrid(
          month: DateTime(2026, 10),
          selected: DateTime(2026, 10, 1),
          now: DateTime(2026, 10, 1, 9),
          eventsByDay: agendaVisibleByDay([
            _ag(1, 7, 'Ana Souza'),
            _ag(2, 9, 'Bruno Lima'),
            _ag(3, 18, 'Carla Dias'),
          ]),
          onSelect: (_) {},
          onSwipe: swipes.add,
        ),
      ),
    ),
  );
  await tester.pump();
  return swipes;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('dois chips por dia e +N do resto', (tester) async {
    await _pump(tester);
    expect(find.text('7h Ana'), findsOneWidget);
    expect(find.text('9h Bruno'), findsOneWidget);
    expect(find.text('18h Carla'), findsNothing);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Outubro 2026'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        agendaMonthDayA11y(day: DateTime(2026, 10, 7), count: 3, isToday: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('arrastar para cima avança o mês, para baixo volta', (
    tester,
  ) async {
    final swipes = await _pump(tester);
    final grade = find.text('15');
    await tester.fling(grade, const Offset(0, -300), 1000);
    await tester.pump();
    await tester.fling(grade, const Offset(0, 300), 1000);
    await tester.pump();
    expect(swipes, [1, -1]);
  });

  testWidgets('setas trocam o mês', (tester) async {
    final swipes = await _pump(tester);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.tap(find.byTooltip('Mês anterior'));
    expect(swipes, [1, -1]);
  });
}
