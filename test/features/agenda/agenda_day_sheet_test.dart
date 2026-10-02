import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/widgets/agenda_day_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Agendamento _ag(int id, DateTime inicio) => Agendamento(
  id: id,
  alunoId: id,
  alunoNome: 'Aluno $id',
  inicio: inicio,
  fim: inicio.add(const Duration(hours: 1)),
  status: 'AGENDADO',
);

Future<void> _pump(
  WidgetTester tester,
  DateTime day,
  List<Agendamento> ags,
  void Function(DateTime?, int?) onNew,
) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: AgendaDaySheet(
          day: day,
          agendamentos: ValueNotifier(ags),
          photoFor: (_) => null,
          onRefresh: () async {},
          onOpen: (_) {},
          onNew: onNew,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  final hoje = DateTime.now();
  final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);
  final ontem = DateTime(hoje.year, hoje.month, hoje.day - 1);

  testWidgets('dia passado mostra os horários mas não agenda', (tester) async {
    await _pump(tester, ontem, [
      _ag(1, DateTime(ontem.year, ontem.month, ontem.day, 8)),
      _ag(2, DateTime(ontem.year, ontem.month, ontem.day, 11)),
    ], (_, _) {});

    expect(find.text('Aluno 1'), findsOneWidget);
    expect(find.text('Dia passado — só consulta.'), findsOneWidget);
    expect(find.textContaining('Agendar em'), findsNothing);
    expect(
      find.textContaining(RegExp('2 horas livres', caseSensitive: false)),
      findsOneWidget,
    );
    expect(find.text('Encaixar'), findsNothing);
  });

  testWidgets('lacuna futura encaixa com início e duração', (tester) async {
    DateTime? inicio;
    int? duracao;
    await _pump(
      tester,
      amanha,
      [
        _ag(1, DateTime(amanha.year, amanha.month, amanha.day, 8)),
        _ag(2, DateTime(amanha.year, amanha.month, amanha.day, 9, 45)),
      ],
      (i, d) {
        inicio = i;
        duracao = d;
      },
    );

    expect(find.textContaining('Agendar em'), findsOneWidget);
    await tester.tap(find.text('Encaixar'));
    await tester.pump();

    expect(inicio, DateTime(amanha.year, amanha.month, amanha.day, 9));
    expect(duracao, 45);
  });
}
