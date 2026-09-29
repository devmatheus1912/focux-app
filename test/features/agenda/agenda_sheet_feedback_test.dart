import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_queued_ack.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/providers/agenda_provider.dart';
import 'package:focux_app/features/agenda/screens/agenda_screen.dart';
import 'package:focux_app/features/agenda/widgets/agenda_next_banner.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

const _conflito = 'Horário conflita com outro agendamento.';
const _pendente = 'Sem conexão. Vamos enviar quando a rede voltar.';

class _FakeAgendaRepository implements AgendaRepository {
  _FakeAgendaRepository({this.statusError, this.excluirError});

  final Object? statusError;
  final Object? excluirError;

  Agendamento get _hoje {
    final now = DateTime.now();
    return Agendamento(
      id: 1,
      alunoId: 5,
      alunoNome: 'Aluno Teste',
      inicio: DateTime(now.year, now.month, now.day, 0, 1),
      fim: DateTime(now.year, now.month, now.day, 23, 59),
      status: 'AGENDADO',
    );
  }

  @override
  Future<AgendaHomeBundle> getHome() async =>
      AgendaHomeBundle(proximos: [_hoje], semana: const []);

  @override
  Future<Agendamento> atualizarStatus(int id, String status) async {
    throw statusError!;
  }

  @override
  Future<void> excluir(int id) async {
    if (excluirError != null) throw excluirError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DioException _http400(String erro) {
  final options = RequestOptions(path: '/api/agenda/1/status');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 400,
      data: {'erro': erro},
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpAgenda(WidgetTester tester, AgendaRepository repo) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(repo),
        alunosProvider.overrideWith((ref) async => const <Aluno>[]),
        alunoProvider.overrideWith(
          (ref, id) async =>
              Aluno(id: id, nome: 'Aluno Teste', email: '', status: 'ATIVO'),
        ),
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
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byType(AgendaNextBanner));
  await _settle(tester);
}

Future<void> _tapInSheet(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AgendaWeekClientCache.clear();
  });

  testWidgets('falha ao confirmar fecha a sheet e mostra o erro do servidor', (
    tester,
  ) async {
    await _pumpAgenda(
      tester,
      _FakeAgendaRepository(statusError: _http400(_conflito)),
    );
    await _openSheet(tester);
    expect(find.byType(BottomSheet), findsOneWidget);

    await _tapInSheet(tester, 'Confirmar horário');

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(_conflito), findsOneWidget);
    expect(find.text('Horário confirmado.'), findsNothing);
  });

  testWidgets('falha ao excluir fecha a sheet e mostra o fallback', (
    tester,
  ) async {
    await _pumpAgenda(
      tester,
      _FakeAgendaRepository(excluirError: StateError('Null check operator')),
    );
    await _openSheet(tester);

    await _tapInSheet(tester, 'Excluir agendamento');
    await _tapInSheet(tester, 'Excluir');

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.text('Não foi possível excluir o atendimento. Tente de novo.'),
      findsOneWidget,
    );
    expect(find.textContaining('Null check'), findsNothing);
    expect(find.text('Agendamento excluído.'), findsNothing);
  });

  testWidgets('exclusão enfileirada offline fecha a sheet e avisa o pendente', (
    tester,
  ) async {
    await _pumpAgenda(
      tester,
      _FakeAgendaRepository(excluirError: const OfflineQueuedException()),
    );
    await _openSheet(tester);

    await _tapInSheet(tester, 'Excluir agendamento');
    await _tapInSheet(tester, 'Excluir');

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(_pendente), findsOneWidget);
    expect(find.text('Agendamento excluído.'), findsNothing);
  });

  testWidgets('status enfileirado offline fecha a sheet e avisa o pendente', (
    tester,
  ) async {
    await _pumpAgenda(
      tester,
      _FakeAgendaRepository(statusError: const OfflineQueuedException()),
    );
    await _openSheet(tester);

    await _tapInSheet(tester, 'Confirmar horário');

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(_pendente), findsOneWidget);
    expect(find.text('Horário confirmado.'), findsNothing);
  });
}
