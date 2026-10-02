import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/providers/agenda_provider.dart';
import 'package:focux_app/features/agenda/screens/agenda_screen.dart';
import 'package:focux_app/features/agenda/utils/agenda_month.dart';
import 'package:focux_app/features/agenda/utils/agenda_schedule.dart';
import 'package:focux_app/features/agenda/widgets/agenda_month_grid.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeRepo implements AgendaRepository {
  final meses = <String>[];

  @override
  Future<List<Agendamento>> listarMes(int ano, int mes) async {
    meses.add('$ano-$mes');
    final hoje = DateTime.now();
    if (ano != hoje.year || mes != hoje.month) return const [];
    final outroDia = hoje.day == 15 ? 16 : 15;
    return [
      Agendamento(
        id: 7,
        alunoId: 3,
        alunoNome: 'Aluno Calendário',
        inicio: DateTime(ano, mes, outroDia, 9),
        fim: DateTime(ano, mes, outroDia, 10),
        status: 'AGENDADO',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_FakeRepo> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(repo),
        alunosProvider.overrideWith((ref) async => const <Aluno>[]),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const AgendaScreen(),
      ),
    ),
  );
  await _settle(tester);
  return repo;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AgendaWeekClientCache.clear();
  });

  testWidgets('tocar no dia com ponto mostra o atendimento', (tester) async {
    await _pump(tester);
    final hoje = DateTime.now();
    final outroDia = hoje.day == 15 ? 16 : 15;
    expect(find.text('Aluno Calendário'), findsNothing);

    final alvo = DateTime(hoje.year, hoje.month, outroDia);
    await tester.tap(
      find.bySemanticsLabel(
        agendaMonthDayA11y(day: alvo, count: 1, isToday: false),
      ),
    );
    await _settle(tester);

    expect(find.text('Aluno Calendário'), findsOneWidget);
  });

  testWidgets('dia vazio abre a folha com Dia livre e Agendar no dia', (
    tester,
  ) async {
    await _pump(tester);
    final hoje = DateTime.now();
    final vazio = DateTime(hoje.year, hoje.month, hoje.day == 20 ? 21 : 20);
    final rotulo = agendaDayShortLabel(vazio);

    expect(find.textContaining('Agendar em'), findsNothing);
    expect(find.text('Dia livre'), findsNothing);
    expect(find.byTooltip('Ir para hoje'), findsNothing);

    await tester.tap(
      find.bySemanticsLabel(
        agendaMonthDayA11y(day: vazio, count: 0, isToday: false),
      ),
    );
    await _settle(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Dia livre'), findsWidgets);
    expect(find.text('Agendar em $rotulo'), findsOneWidget);
    expect(find.byTooltip('Ir para hoje'), findsOneWidget);
  });

  testWidgets('arrastar o calendário troca o mês e Hoje volta', (tester) async {
    final repo = await _pump(tester);
    final hoje = DateTime.now();
    final proximo = agendaShiftMonth(agendaMonthOf(hoje), 1);

    await tester.fling(
      find.byType(AgendaMonthGrid),
      const Offset(-300, 0),
      1000,
    );
    await _settle(tester);

    expect(find.text(agendaMonthLabel(proximo)), findsOneWidget);
    expect(repo.meses.last, '${proximo.year}-${proximo.month}');

    await tester.tap(find.byTooltip('Ir para hoje'));
    await _settle(tester);
    expect(find.text(agendaMonthLabel(agendaMonthOf(hoje))), findsOneWidget);
  });
}
