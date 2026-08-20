import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/agenda/utils/agenda_schedule.dart';
import 'package:focux_app/features/agenda/widgets/agenda_day_empty_panel.dart';

void main() {
  testWidgets('empty do dia traz data, copy e CTA no mesmo card', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaDayEmptyPanel(
            dayLabel: 'Qui · 20 ago',
            onNew: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Qui · 20 ago'), findsOneWidget);
    expect(find.text('Dia livre'), findsOneWidget);
    expect(find.text(agendaEmptyDayHint()), findsOneWidget);
    expect(find.byType(FxLiquidPrimaryButton), findsOneWidget);

    await tester.tap(find.text('Novo agendamento'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
