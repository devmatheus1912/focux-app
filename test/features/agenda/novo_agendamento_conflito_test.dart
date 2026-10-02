import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_novo_args.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/providers/agenda_provider.dart';
import 'package:focux_app/features/agenda/screens/novo_agendamento_screen.dart';
import 'package:focux_app/features/agenda/widgets/agenda_slot_picker_sheet.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

const _ocupado = 'Horário ocupado: Nathalia 15:00–16:00.';

class _FakeRepo implements AgendaRepository {
  final meses = <String>[];
  var criados = 0;

  @override
  Future<Agendamento> criar(
    int alunoId,
    DateTime inicio,
    DateTime fim,
    String? titulo,
  ) async {
    criados++;
    final options = RequestOptions(path: '/api/agenda');
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 409,
        data: {'erro': _ocupado, 'codigo': 'AGENDA_CONFLITO'},
      ),
    );
  }

  @override
  Future<List<Agendamento>> listarMes(int ano, int mes) async {
    meses.add('$ano-$mes');
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('409 de conflito mostra o motivo e reabre a grade', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    final hoje = DateTime.now();
    final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agendaRepositoryProvider.overrideWithValue(repo),
          alunosProvider.overrideWith(
            (ref) async => [
              Aluno(id: 9, nome: 'Bruno', email: '', status: 'ATIVO'),
            ],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: NovoAgendamentoScreen(
            args: AgendaNovoArgs(
              day: amanha,
              inicio: amanha.add(const Duration(hours: 15)),
              agendamentos: const [],
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.textContaining('15:00–16:00'), findsOneWidget);

    await tester.tap(find.text('Aluno'));
    await _settle(tester);
    await tester.tap(find.text('Bruno'));
    await _settle(tester);

    await tester.tap(find.text('Agendar atendimento'));
    await _settle(tester);
    await tester.tap(find.text('Agendar atendimento').last);
    await _settle(tester);

    expect(repo.criados, 1);
    expect(find.text(_ocupado), findsOneWidget);
    expect(find.byType(AgendaSlotPickerSheet), findsOneWidget);
    expect(repo.meses, ['${amanha.year}-${amanha.month}']);
  });
}
