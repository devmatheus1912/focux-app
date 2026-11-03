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

Map<String, Object> _aluno(
  int id,
  String nome,
  String nivel, {
  List<String> motivos = const ['Sem treino há 12 dias'],
  bool cobravel = false,
}) => {
  'alunoId': id,
  'alunoNome': nome,
  'nivel': nivel,
  'motivos': nivel == 'BAIXO' ? const <String>[] : motivos,
  'cobravel': cobravel,
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
        'top3': alunos.where((a) => a['nivel'] != 'BAIXO').take(3).toList(),
      };
    } else if (options.path == '/api/retencao/base') {
      final q = (options.queryParameters['q'] as String? ?? '').toLowerCase();
      final nivel = options.queryParameters['nivel'];
      final lista =
          alunos
              .where(
                (a) =>
                    (a['alunoNome'] as String).toLowerCase().contains(q) &&
                    (nivel == null || a['nivel'] == nivel),
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
  _aluno(1, 'Hugo', 'ALTO'),
  _aluno(2, 'Iara', 'ALTO'),
  _aluno(3, 'João', 'ALTO'),
  _aluno(4, 'Kátia', 'ALTO'),
  _aluno(5, 'Léo', 'ALTO'),
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

  testWidgets('cada aluno mostra o motivo, sem nota de 0 a 100', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
    await _settle(tester);
    expect(find.text('Chamar agora'), findsOneWidget);
    expect(find.text('Hugo'), findsOneWidget);
    expect(find.text('Léo'), findsOneWidget);
    expect(find.text('Sem treino há 12 dias'), findsNWidgets(5));
    expect(find.textContaining('de 100'), findsNothing);
  });

  testWidgets('"Mensagem" abre o chat de quem está em Chamar agora', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
    await _settle(tester);
    await tester.tap(find.text('Mensagem').first);
    await _settle(tester);
    expect(find.text('CHAT 1'), findsOneWidget);
  });

  testWidgets('tocar no número filtra pelo servidor', (tester) async {
    telaAlta(tester);
    final adapter = _Adapter(
      alunos: [
        _aluno(1, 'Hugo', 'ALTO'),
        _aluno(2, 'Iara', 'MEDIO'),
        _aluno(3, 'João', 'BAIXO'),
      ],
      alto: 1,
      medio: 1,
      saudavel: 1,
    );
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);
    await tester.tap(find.text('Em dia').first);
    await _settle(tester);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Iara'), findsNothing);
    expect(adapter.chamadas.last, contains('nivel: BAIXO'));
    await tester.tap(find.text('Todos'));
    await _settle(tester);
    expect(find.text('Iara'), findsOneWidget);
  });

  testWidgets('busca aparece com lista grande e vai ao servidor', (tester) async {
    telaAlta(tester);
    final adapter = _Adapter(alunos: _cinco, alto: 9);
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Léo');
    await tester.pump(const Duration(milliseconds: 600));
    await _settle(tester);
    expect(adapter.chamadas.last, contains('q: Léo'));
  });

  testWidgets('sem ninguém para chamar: frase curta', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(
      _app(_Adapter(alunos: [_aluno(1, 'Ana', 'BAIXO')], alto: 0, saudavel: 1)),
    );
    await _settle(tester);
    expect(find.text('Ninguém para chamar agora.'), findsOneWidget);
    expect(find.text('Mensagem'), findsNothing);
  });

  testWidgets('Cobrar só aparece quando há mensalidade em atraso', (tester) async {
    telaAlta(tester);
    final lista = [
      _aluno(1, 'A', 'ALTO'),
      _aluno(2, 'B', 'ALTO'),
      _aluno(3, 'C', 'ALTO'),
      _aluno(4, 'Hugo', 'ALTO'),
      _aluno(5, 'Iara', 'ALTO', cobravel: true),
    ];
    await tester.pumpWidget(_app(_Adapter(alunos: lista, alto: 5)));
    await _settle(tester);
    await tester.tap(find.text('Hugo'));
    await _settle(tester);
    expect(find.text('Adiar 24 h'), findsOneWidget);
    expect(find.text('Cobrar'), findsNothing);
  });

  testWidgets('Histórico e Cobrança ficam no menu do topo', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(alunos: _cinco, alto: 5)));
    await _settle(tester);
    expect(find.text('Histórico de retomada'), findsNothing);
    await tester.tap(find.byTooltip('Mais ações'));
    await _settle(tester);
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
