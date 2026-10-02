import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/agenda/screens/agenda_aluno_screen.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoje = DateTime.now();
final _amanha = DateTime(_hoje.year, _hoje.month, _hoje.day + 1, 8, 30);
final _depois = DateTime(_hoje.year, _hoje.month, _hoje.day + 3, 12);
final _passada = DateTime(_hoje.year, _hoje.month, _hoje.day - 5, 12);

Map<String, Object?> _ag(
  int id,
  DateTime inicio,
  String status, {
  String? titulo,
  String? atendimento,
}) => {
  'id': id,
  'alunoId': 1,
  'alunoNome': 'Aluno Exemplo',
  'inicio': inicio.toIso8601String(),
  'fim': inicio.add(const Duration(hours: 1)).toIso8601String(),
  'titulo': titulo,
  'status': status,
  'statusAtendimento': atendimento,
};

Map<String, Object?> _pagina(List<Object> content) => {
  'content': content,
  'hasNext': false,
  'page': 0,
  'totalElements': content.length,
};

class _Adapter implements HttpClientAdapter {
  final escopos = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (options.path == '/api/agenda/aluno/meus') {
      final escopo = options.queryParameters['escopo'];
      escopos.add(escopo);
      body =
          escopo == 'proximas'
              ? _pagina([
                _ag(1, _amanha, 'AGENDADO', titulo: 'Avaliação'),
                _ag(2, _depois, 'CONFIRMADO'),
              ])
              : _pagina([
                _ag(3, _passada, 'AGENDADO', titulo: 'Treino antigo'),
                _ag(
                  4,
                  _passada.subtract(const Duration(days: 7)),
                  'CONFIRMADO',
                  titulo: 'Treino com presença',
                  atendimento: 'PRESENTE',
                ),
              ]);
    } else if (options.path == '/api/agenda/1/confirmar') {
      body = _ag(1, _amanha, 'CONFIRMADO', titulo: 'Avaliação');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Adapter> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final adapter = _Adapter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(
          _FakeApiClient(Dio()..httpClientAdapter = adapter),
        ),
        alunoDashboardHomeProvider.overrideWith(
          (ref) => Completer<AlunoDashboardHomeBundle>().future,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const AgendaAlunoScreen(),
      ),
    ),
  );
  await _settle(tester);
  return adapter;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('separa próximas e anteriores com rótulo do dia', (tester) async {
    final adapter = await _pump(tester);

    expect(adapter.escopos, containsAll(['proximas', 'anteriores']));
    expect(find.text('Próximas'), findsOneWidget);
    expect(find.text('Anteriores'), findsOneWidget);
    expect(find.text('Amanhã · 08:30–09:30'), findsOneWidget);
    expect(find.text('4 compromissos'), findsNothing);
    expect(find.textContaining('4 compromissos'), findsOneWidget);
    expect(find.byTooltip('Adicionar ao calendário'), findsOneWidget);

    expect(find.text('Treino antigo'), findsNothing);
    await tester.tap(find.text('Ver anteriores'));
    await tester.pump();

    expect(find.text('Treino antigo'), findsOneWidget);
    expect(find.text('Compareceu'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('confirmar atualiza a sessão sem recarregar a lista', (
    tester,
  ) async {
    final adapter = await _pump(tester);
    final chamadas = adapter.escopos.length;

    await tester.tap(find.text('Confirmar'));
    await _settle(tester);
    expect(find.text('Confirmar presença?'), findsOneWidget);

    await tester.tap(find.text('Confirmar').last);
    await _settle(tester);

    expect(find.text('Avaliação'), findsOneWidget);
    expect(find.text('Confirmado'), findsNWidgets(2));
    expect(adapter.escopos.length, chamadas);
  });
}
