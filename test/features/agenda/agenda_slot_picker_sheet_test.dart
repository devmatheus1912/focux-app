import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_home_sheet.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/widgets/agenda_slot_picker_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

final _now = DateTime(2026, 11, 20, 10, 10);
final _dia = DateTime(2026, 11, 20);

final _nathalia = Agendamento(
  id: 4,
  alunoId: 2,
  alunoNome: 'Nathalia Souza',
  inicio: DateTime(2026, 11, 20, 15),
  fim: DateTime(2026, 11, 20, 16),
  status: 'CONFIRMADO',
);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: home),
);

AgendaSlotPickerSheet _sheet({int? excludeId, List<Agendamento>? ags}) =>
    AgendaSlotPickerSheet(
      title: 'Início do atendimento',
      day: _dia,
      agendamentos: ags ?? [_nathalia],
      excludeId: excludeId,
      now: _now,
    );

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home));
  await tester.pump();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('abre no dia escolhido, sem faixa de 14 dias', (tester) async {
    await _pump(tester, _sheet());

    expect(find.text('Sex, 20 nov'), findsOneWidget);
    expect(find.text('Trocar dia'), findsOneWidget);
    expect(find.text('Sáb'), findsNothing);
    expect(find.text('21'), findsNothing);
  });

  testWidgets('horários passados de hoje somem', (tester) async {
    await _pump(tester, _sheet());

    expect(find.text('10:00'), findsNothing);
    expect(find.text('06:00'), findsNothing);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('22:30'), findsOneWidget);
  });

  testWidgets('horário ocupado fica desabilitado com o nome do aluno', (
    tester,
  ) async {
    await _pump(tester, _sheet());

    expect(find.text('Nathalia'), findsNWidgets(3));
    expect(
      find.bySemanticsLabel('Horário 14:30, ocupado por Nathalia'),
      findsOneWidget,
    );
    expect(find.text('Confirmar horário · 10:30–11:30'), findsOneWidget);

    await tester.tap(find.text('15:00'));
    await tester.pump();
    expect(find.text('Confirmar horário · 10:30–11:30'), findsOneWidget);

    await tester.tap(find.text('16:00'));
    await tester.pump();
    expect(find.text('Confirmar horário · 16:00–17:00'), findsOneWidget);
  });

  testWidgets('duração muda o fim e libera o horário encostado', (
    tester,
  ) async {
    await _pump(tester, _sheet());

    await tester.tap(find.text('30 min'));
    await tester.pump();

    expect(find.text('Confirmar horário · 10:30–11:00'), findsOneWidget);
    expect(find.text('Nathalia'), findsNWidgets(2));

    await tester.tap(find.text('1h30'));
    await tester.pump();
    expect(find.text('Confirmar horário · 10:30–12:00'), findsOneWidget);
    expect(find.text('Nathalia'), findsNWidgets(4));
  });

  testWidgets('remarcação não se bloqueia', (tester) async {
    await _pump(tester, _sheet(excludeId: _nathalia.id));

    expect(find.text('Nathalia'), findsNothing);
  });

  testWidgets('trocar dia abre o mês e não deixa voltar ao passado', (
    tester,
  ) async {
    await _pump(tester, _sheet());

    await tester.tap(find.text('Trocar dia'));
    await tester.pump();

    expect(find.text('Novembro 2026'), findsOneWidget);
    expect(find.byTooltip('Mês anterior'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.chevron_left_rounded),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('19'));
    await tester.pump();
    expect(find.text('Novembro 2026'), findsOneWidget);

    await tester.tap(find.text('21'));
    await tester.pump();
    expect(find.text('Sáb, 21 nov'), findsOneWidget);
    expect(find.text('06:00'), findsOneWidget);
    expect(find.text('Nathalia'), findsNothing);
  });

  testWidgets('confirmar devolve início e duração', (tester) async {
    AgendaSlotPick? result;
    await _pump(
      tester,
      Builder(
        builder:
            (context) => TextButton(
              onPressed: () async {
                result = await showFxHomeSheet<AgendaSlotPick>(
                  context,
                  builder: (_) => _sheet(),
                );
              },
              child: const Text('abrir'),
            ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('45 min'));
    await tester.pump();
    await tester.tap(find.text('Confirmar horário · 10:30–11:15'));
    await tester.pumpAndSettle();

    expect(result?.inicio, DateTime(2026, 11, 20, 10, 30));
    expect(result?.duracaoMin, 45);
    expect(result?.fim, DateTime(2026, 11, 20, 11, 15));
  });

  testWidgets('sem lista pronta busca o mês pelo loader', (tester) async {
    final meses = <DateTime>[];
    await _pump(
      tester,
      AgendaSlotPickerSheet(
        title: 'Início do atendimento',
        day: _dia,
        now: _now,
        loadMonth: (month) async {
          meses.add(month);
          return [_nathalia];
        },
      ),
    );
    await tester.pump();

    expect(meses, [DateTime(2026, 11)]);
    expect(find.text('Nathalia'), findsNWidgets(3));
  });
}
