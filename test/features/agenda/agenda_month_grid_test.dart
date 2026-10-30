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

Future<List<int>> _pump(WidgetTester tester, {bool expand = false}) async {
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
          expand: expand,
        ),
      ),
    ),
  );
  await tester.pump();
  return swipes;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('tela inteira: semanas esticam e o dia mostra a contagem', (
    tester,
  ) async {
    await _pump(tester, expand: true);
    expect(find.text('3'), findsWidgets);
    expect(find.text('7h Ana'), findsNothing);
    final cell = tester.getSize(
      find.bySemanticsLabel(
        agendaMonthDayA11y(
          day: DateTime(2026, 10, 7),
          count: 3,
          isToday: false,
        ),
      ),
    );
    expect(cell.height, greaterThan(AgendaMonthGrid.cellHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitor de tela ouve a contagem do dia', (tester) async {
    await _pump(tester);
    expect(find.text('Outubro 2026'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        agendaMonthDayA11y(
          day: DateTime(2026, 10, 7),
          count: 3,
          isToday: false,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('arrastar na horizontal troca o mês; na vertical, não', (
    tester,
  ) async {
    final swipes = await _pump(tester);
    final grade = find.text('15');
    await tester.fling(grade, const Offset(0, -300), 1000);
    await tester.pump();
    expect(swipes, isEmpty);
    await tester.fling(grade, const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.fling(grade, const Offset(300, 0), 1000);
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
