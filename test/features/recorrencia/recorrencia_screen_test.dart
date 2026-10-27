import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/recorrencia/screens/recorrencia_screen.dart';
import 'package:focux_app/features/recorrencia/utils/recorrencia_display.dart';
import 'package:focux_app/features/recorrencia/widgets/recorrencia_nova_folha.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

class _Chamada {
  _Chamada(this.metodo, this.path, this.corpo);

  final String metodo;
  final String path;
  final Object? corpo;
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.itens = const []});

  final List<Map<String, Object>> itens;
  final List<_Chamada> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(_Chamada(options.method, options.path, options.data));
    Object? body;
    switch ('${options.method} ${options.path}') {
      case 'GET /api/recorrencia':
        body = {
          'content': itens,
          'page': 0,
          'size': 20,
          'totalElements': itens.length,
          'hasNext': false,
        };
      case 'GET /api/dunning/home':
        body = {
          'snapshot': {
            'total': 0,
            'abertas': 0,
            'recuperadas': 0,
            'recoveryRate': 0,
          },
          'falhas': <dynamic>[],
        };
      case 'GET /api/financeiro/mensalidades':
        body = {
          'mensalidades': [
            {
              'id': 1,
              'alunoId': 3,
              'alunoNome': 'Beto',
              'valor': '150.00',
              'mesReferencia': '2026-09-01',
              'status': 'PAGO',
            },
          ],
          'page': 0,
          'size': 1,
          'hasMore': false,
        };
      case 'POST /api/recorrencia':
        body = {
          'id': 5,
          'alunoId': 3,
          'alunoNome': 'Beto',
          'valor': '150.00',
          'status': 'PENDENTE',
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

PerfilPersonal _perfil({String? chave}) => PerfilPersonal(
  id: 1,
  nome: 'Pat',
  email: 'pat@example.com',
  plano: 'PRO',
  chavePix: chave,
  tipoChavePix: chave == null ? null : 'CPF',
);

Widget _app(_Adapter adapter, Widget home, {String? chave}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: home)),
      GoRoute(
        path: '/perfil/wallet',
        builder: (_, _) => const Scaffold(body: Text('CARTEIRA')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
      perfilProvider.overrideWith((ref) async => _perfil(chave: chave)),
    ],
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

const _item = {
  'id': 1,
  'alunoId': 3,
  'alunoNome': 'Beto',
  'valor': '150.00',
  'status': 'ATIVA',
  'proximaCobranca': '2026-11-05',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  group('lista de recorrências', () {
    testWidgets('vazia: convite, explicação e nenhum filtro', (tester) async {
      telaAlta(tester);
      await tester.pumpWidget(
        _app(_Adapter(), const RecorrenciaScreen(embedded: true)),
      );
      await _settle(tester);
      expect(find.text('Nenhuma recorrência ainda'), findsOneWidget);
      expect(
        find.text('Cria a mensalidade sozinha todo mês e gera o PIX do aluno.'),
        findsOneWidget,
      );
      expect(find.text('Todas'), findsNothing);
      expect(find.text('Pendentes'), findsNothing);
      expect(find.text('Buscar aluno'), findsNothing);
      expect(find.textContaining('ssinatura'), findsNothing);
      expect(find.text('Nova recorrência'), findsOneWidget);
    });

    testWidgets('sem chave PIX: linha de pré-requisito e aviso ao criar', (
      tester,
    ) async {
      telaAlta(tester);
      await tester.pumpWidget(
        _app(_Adapter(), const RecorrenciaScreen(embedded: true)),
      );
      await _settle(tester);
      expect(find.text('Cadastre sua chave PIX para cobrar'), findsOneWidget);
      await tester.tap(find.text('Nova recorrência'));
      await _settle(tester);
      expect(find.text('Falta a chave PIX'), findsOneWidget);
      expect(find.text('Cadastrar chave'), findsOneWidget);
      await tester.tap(find.text('Cadastrar chave'));
      await _settle(tester);
      expect(find.text('CARTEIRA'), findsOneWidget);
    });

    testWidgets(
      'com chave PIX: sem pré-requisito, mostra a cobrança automática',
      (tester) async {
        telaAlta(tester);
        await tester.pumpWidget(
          _app(
            _Adapter(),
            const RecorrenciaScreen(embedded: true),
            chave: '12345678901',
          ),
        );
        await _settle(tester);
        expect(find.text('Cadastre sua chave PIX para cobrar'), findsNothing);
        expect(find.text('Cobrança automática'), findsOneWidget);
        expect(find.text('Ligada · sem falhas'), findsOneWidget);
      },
    );

    testWidgets('com itens: filtros e seção Recorrências', (tester) async {
      telaAlta(tester);
      await tester.pumpWidget(
        _app(
          _Adapter(itens: const [_item]),
          const RecorrenciaScreen(embedded: true),
          chave: '12345678901',
        ),
      );
      await _settle(tester);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.text('Recorrências'), findsOneWidget);
      expect(find.text('Beto'), findsOneWidget);
    });

    for (final tela in kDynamicTypeTelas) {
      testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
        usarDynamicTypeMaximo(tester, tela);
        await tester.pumpWidget(
          _app(
            _Adapter(itens: const [_item]),
            const RecorrenciaScreen(embedded: true),
          ),
        );
        await _settle(tester);
        final ex = tester.takeException();
        expect(ex, isNull, reason: ex?.toString());
      });
    }
  });

  group('folha Nova recorrência', () {
    Future<void> abrir(WidgetTester tester, _Adapter adapter) async {
      await tester.pumpWidget(
        _app(
          adapter,
          Consumer(
            builder:
                (context, ref, _) => Center(
                  child: TextButton(
                    onPressed:
                        () => showRecorrenciaNovaFolha(
                          context,
                          ref,
                          alunoId: 3,
                          alunoNome: 'Beto',
                        ),
                    child: const Text('abrir'),
                  ),
                ),
          ),
          chave: '12345678901',
        ),
      );
      await tester.tap(find.text('abrir'));
      await _settle(tester);
    }

    testWidgets('sem 199: o valor vem da última mensalidade do aluno', (
      tester,
    ) async {
      telaAlta(tester);
      await abrir(tester, _Adapter());
      expect(find.text('Nova recorrência'), findsOneWidget);
      expect(find.text('Beto'), findsOneWidget);
      expect(find.text('199'), findsNothing);
      final campo = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(campo.controller?.text, '150.00');
      expect(
        find.text(
          'Todo dia ${recorrenciaDiaPadrao(DateTime.now())} · R\$ 150,00 · PIX',
        ),
        findsOneWidget,
      );
    });

    testWidgets('criar envia valor e dia, e fecha', (tester) async {
      telaAlta(tester);
      final adapter = _Adapter();
      await abrir(tester, adapter);
      await tester.tap(find.text('Criar recorrência'));
      await _settle(tester);
      final post = adapter.chamadas.singleWhere(
        (c) => c.metodo == 'POST' && c.path == '/api/recorrencia',
      );
      final corpo = post.corpo as Map;
      expect(corpo['alunoId'], 3);
      expect(corpo['valor'], '150.00');
      expect(corpo['diaVencimento'], recorrenciaDiaPadrao(DateTime.now()));
      expect(find.text('Criar recorrência'), findsNothing);
    });
  });
}
