import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/screens/financeiro_mensalidades_tab.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Chamada {
  _Chamada(this.metodo, this.path, this.query, this.corpo);

  final String metodo;
  final String path;
  final Map<String, dynamic> query;
  final Object? corpo;
}

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.atrasadas});

  final int atrasadas;
  final List<_Chamada> chamadas = [];

  Iterable<_Chamada> get listas => chamadas.where(
    (c) => c.metodo == 'GET' && c.path == '/api/financeiro/mensalidades',
  );

  static Map<String, Object> _item(int id, String nome, String status) => {
    'id': id,
    'alunoId': id,
    'alunoNome': nome,
    'valor': '100.00',
    'mesReferencia': '2026-10-01',
    'vencimento': '2026-10-05',
    'status': status,
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(
      _Chamada(
        options.method,
        options.path,
        Map<String, dynamic>.from(options.queryParameters),
        options.data,
      ),
    );
    Object? body;
    if (options.path == '/api/financeiro/home') {
      body = {
        'dashboard': {
          'receitaMes': '0',
          'receitaAcumulada': '0',
          'ticketMedio': '0',
          'totalInadimplentes': 0,
          'previsaoReceita': '0',
          'vencimentosProximos': <dynamic>[],
          'topAlunos': <dynamic>[],
          'evolucaoMensal': <dynamic>[],
        },
        'mensalidades': [_item(1, 'Ana Aberta', 'PENDENTE')],
        'resumoMesAtual': {
          'totalRecebido': '0',
          'totalPrevisto': '0',
          'inadimplentes': atrasadas,
          'ticketMedio': '0',
          'acumuladoAnual': '0',
          'quantidadeAtrasadas': atrasadas,
        },
      };
    } else if (options.path == '/api/financeiro/mensalidades' &&
        options.method == 'GET') {
      final status = options.queryParameters['status'];
      body = {
        'mensalidades': [
          _item(2, 'Beto', status == 'ATRASADAS' ? 'ATRASADO' : 'PAGO'),
        ],
        'page': 0,
        'size': 20,
        'hasMore': false,
      };
    } else if (options.path == '/api/financeiro/mensalidades' &&
        options.method == 'POST') {
      body = _item(9, 'Criada', 'PENDENTE');
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

Widget _app(_Adapter adapter, Widget Function() tab) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => Scaffold(body: tab()))],
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('com atraso a lista abre em Atrasadas', (tester) async {
    telaAlta(tester);
    final adapter = _Adapter(atrasadas: 2);
    await tester.pumpWidget(
      _app(adapter, () => const FinanceiroMensalidadesTab()),
    );
    await _settle(tester);
    expect(adapter.listas.map((c) => c.query['status']), ['ATRASADAS']);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Ana Aberta'), findsNothing);
  });

  testWidgets('sem atraso a lista abre em Em aberto, pela home', (
    tester,
  ) async {
    telaAlta(tester);
    final adapter = _Adapter(atrasadas: 0);
    await tester.pumpWidget(
      _app(adapter, () => const FinanceiroMensalidadesTab()),
    );
    await _settle(tester);
    expect(adapter.listas, isEmpty);
    expect(find.text('Ana Aberta'), findsOneWidget);
  });

  testWidgets('não há mais "Atualizar atrasos" nem chamada ao agendador', (
    tester,
  ) async {
    telaAlta(tester);
    final adapter = _Adapter(atrasadas: 2);
    await tester.pumpWidget(
      _app(adapter, () => const FinanceiroMensalidadesTab()),
    );
    await _settle(tester);
    expect(find.text('Atualizar atrasos'), findsNothing);
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await _settle(tester);
    expect(
      adapter.chamadas.where((c) => c.path.contains('atualizar-atrasos')),
      isEmpty,
    );
  });

  testWidgets('filtro pedido de fora (toque nos números) troca a lista', (
    tester,
  ) async {
    telaAlta(tester);
    final adapter = _Adapter(atrasadas: 0);
    final token = ValueNotifier<int>(0);
    await tester.pumpWidget(
      _app(
        adapter,
        () => ValueListenableBuilder<int>(
          valueListenable: token,
          builder:
              (_, t, _) => FinanceiroMensalidadesTab(
                filtroPedido: t == 0 ? null : MensalidadeFiltro.pagas,
                filtroToken: t,
              ),
        ),
      ),
    );
    await _settle(tester);
    token.value = 1;
    await _settle(tester);
    expect(adapter.listas.map((c) => c.query['status']), ['PAGAS']);
    expect(find.text('Beto'), findsOneWidget);
  });

  test('criar envia o vencimento escolhido', () async {
    final adapter = _Adapter(atrasadas: 0);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    await FinanceiroRepository(_FakeApiClient(dio)).criar(
      3,
      FxMoney.fromInput('150'),
      '2026-10-01',
      vencimento: '2026-10-31',
    );
    final post = adapter.chamadas.singleWhere((c) => c.metodo == 'POST');
    expect(post.corpo, {
      'alunoId': 3,
      'valor': '150.00',
      'mesReferencia': '2026-10-01',
      'vencimento': '2026-10-31',
    });
  });

  test('criar sem vencimento mantém o corpo antigo', () async {
    final adapter = _Adapter(atrasadas: 0);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    await FinanceiroRepository(
      _FakeApiClient(dio),
    ).criar(3, FxMoney.fromInput('150'), '2026-10-01');
    final post = adapter.chamadas.singleWhere((c) => c.metodo == 'POST');
    expect((post.corpo as Map).containsKey('vencimento'), isFalse);
  });
}
