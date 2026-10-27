import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/retencao/screens/churn_dashboard_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

Map<String, Object> _aluno(int id, String nome, int score, {int delta = 0}) => {
  'alunoId': id,
  'alunoNome': nome,
  'scoreAtual': score,
  'delta': delta,
  'riscoChurn': score < 40 ? 'ALTO' : (score < 70 ? 'MEDIO' : 'BAIXO'),
};

class _Adapter implements HttpClientAdapter {
  _Adapter({
    required this.alunos,
    required this.alto,
    this.medio = 0,
    this.saudavel = 0,
  });

  final List<Map<String, Object>> alunos;
  final int alto, medio, saudavel;
  final List<String> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add('${options.path} ${options.queryParameters}');
    Object? body;
    if (options.path == '/api/retencao/home') {
      body = {
        'alto': alto,
        'medio': medio,
        'saudavel': saudavel,
        'top3': alunos.take(3).toList(),
      };
    } else if (options.path == '/api/retencao/base') {
      final q = (options.queryParameters['q'] as String? ?? '').toLowerCase();
      final lista =
          alunos
              .where(
                (a) => (a['alunoNome'] as String).toLowerCase().contains(q),
              )
              .toList();
      body = {
        'content': lista,
        'page': 0,
        'totalElements': lista.length,
        'hasNext': false,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? {'erro': 'rota fora do teste'}),
      body == null ? 404 : 200,
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

Widget _app(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ChurnDashboardScreen()),
      GoRoute(
        path: '/alunos/:id/chat',
        builder:
            (_, s) => Scaffold(body: Text('CHAT ${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/winback',
        builder: (_, _) => const Scaffold(body: Text('WINBACK')),
      ),
      GoRoute(
        path: '/dunning',
        builder: (_, _) => const Scaffold(body: Text('DUNNING')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
        useMaterial3: true,
      ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _cinco = [
  _aluno(1, 'Hugo', 10, delta: -5),
  _aluno(2, 'Iara', 15),
  _aluno(3, 'João', 20),
  _aluno(4, 'Kátia', 25),
  _aluno(5, 'Léo', 30),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    '5 em risco alto: Hugo uma vez só, fila sem repetir, sem filtros',
    (tester) async {
      telaAlta(tester);
      await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
      await _settle(tester);
      expect(find.text('Alunos em risco'), findsWidgets);
      expect(find.text('Chamar agora'), findsOneWidget);
      expect(find.text('Hugo'), findsOneWidget); // destaque; fora da fila
      expect(find.text('Iara'), findsOneWidget);
      expect(find.text('Léo'), findsOneWidget);
      expect(find.text('Saúde 10 de 100 · caiu 5 pts'), findsOneWidget);
      // um grupo só: nada de chips que repetem "Todos"
      expect(find.text('Todos'), findsNothing);
      expect(find.text('Ver todos'), findsNothing);
      expect(find.text('Base toda'), findsNothing);
      expect(find.text('Saúde da base'), findsNothing);
      expect(find.text('Chamar'), findsOneWidget);
    },
  );

  testWidgets('"Chamar" abre o chat do primeiro', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
    await _settle(tester);
    await tester.tap(find.text('Chamar'));
    await _settle(tester);
    expect(find.text('CHAT 1'), findsOneWidget);
  });

  testWidgets('grupos mistos: aparecem os chips e o filtro funciona', (
    tester,
  ) async {
    telaAlta(tester);
    final lista = [
      _aluno(1, 'Hugo', 10),
      _aluno(2, 'Iara', 55),
      _aluno(3, 'João', 90),
    ];
    await tester.pumpWidget(
      _app(_Adapter(alunos: lista, alto: 1, medio: 1, saudavel: 1)),
    );
    await _settle(tester);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Iara'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    // filtra pelo chip de saudáveis (o da faixa de números tem o mesmo rótulo)
    await tester.tap(find.text('Saudáveis').last);
    await _settle(tester);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Iara'), findsNothing);
  });

  testWidgets('a busca filtra a fila', (tester) async {
    telaAlta(tester);
    final adapter = _Adapter(alunos: _cinco, alto: 5);
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Léo');
    await tester.pump(const Duration(milliseconds: 600));
    await _settle(tester);
    expect(find.text('Léo'), findsWidgets); // campo + linha da fila
    expect(find.text('Iara'), findsNothing);
  });

  testWidgets('sem ninguém em risco alto: aviso claro, sem botão de chamar', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(
      _app(_Adapter(alunos: [_aluno(1, 'Ana', 90)], alto: 0, saudavel: 1)),
    );
    await _settle(tester);
    expect(find.text('Ninguém em risco alto agora'), findsOneWidget);
    expect(find.text('Chamar'), findsNothing);
  });

  testWidgets('linhas de entrada para retomada e cobrança automática', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
    await _settle(tester);
    expect(find.text('Histórico de retomada'), findsOneWidget);
    expect(find.text('Cobrança automática'), findsOneWidget);
    await tester.tap(find.text('Histórico de retomada'));
    await _settle(tester);
    expect(find.text('WINBACK'), findsOneWidget);
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }
}
