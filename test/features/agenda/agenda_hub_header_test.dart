import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_help.dart';
import 'package:focux_app/features/agenda/widgets/agenda_hub_header.dart';

void main() {
  testWidgets('calendário ao lado do help dispara iCal, não a ajuda', (
    tester,
  ) async {
    var help = 0;
    var ical = 0;
    var created = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaHubHeader(
            freshnessLabel: 'Atualizado agora',
            onHelp: () => help++,
            onIcal: () => ical++,
            onNew: () => created++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Exportar iCal'));
    await tester.pump();

    expect(ical, 1);
    expect(help, 0);
    expect(created, 0);

    await tester.tap(find.byTooltip('Novo agendamento'));
    await tester.pump();
    expect(created, 1);

    await tester.tap(find.byType(FxHelpIconButton));
    await tester.pump();
    expect(help, 1);
    expect(ical, 1);
  });
}
