import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/screens/financeiro_aluno_screen.dart';
import 'package:focux_app/features/financeiro/utils/mensalidade_surface_actions.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _listaPath = '/api/financeiro/mensalidades/aluno/minhas';
const _pixPath = '$_listaPath/7/pix';
const _avisoPath = '$_listaPath/7/avisar-pagamento';

class _RotasAdapter implements HttpClientAdapter {
  _RotasAdapter(this.rotas);

  final Map<String, Object> rotas;
  final List<String> chamadas = [];

  Iterable<String> get listas =>
      chamadas.where((c) => c.startsWith('GET $_listaPath?'));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final page = options.queryParameters['page'];
    final chave =
        '${options.method} ${options.path}${page == null ? '' : '?page=$page'}';
    chamadas.add(chave);
    final body = rotas[chave];
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

Map<String, Object> _mensalidadeJson({int id = 7, String mes = '2026-09'}) => {
  'id': id,
  'alunoId': 3,
  'alunoNome': 'Aluno Teste',
  'valor': '149.90',
  'mesReferencia': '$mes-01',
  'vencimento': '$mes-10',
  'status': 'PENDENTE',
};

Map<String, Object> _pagina(
  int page,
  List<Map<String, Object>> itens, {
  required bool hasMore,
}) => {'mensalidades': itens, 'page': page, 'size': 20, 'hasMore': hasMore};

_RotasAdapter _adapter({bool duasPaginas = false}) => _RotasAdapter({
  'GET $_listaPath?page=0': _pagina(0, [
    _mensalidadeJson(),
  ], hasMore: duasPaginas),
  if (duasPaginas)
    'GET $_listaPath?page=1': _pagina(1, [
      _mensalidadeJson(id: 8, mes: '2026-08'),
    ], hasMore: false),
  'POST $_pixPath': {
    'paymentId': 1,
    'pixCopiaECola': '00020126PIXTESTE',
    'qrCodeBase64': '',
    'status': 'pending',
  },
  'POST $_avisoPath': {'ok': true},
});

Widget _app({required _RotasAdapter adapter, required Widget home}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
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

final _truncado = RegExp(r'R\$ 149(?!,)');

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

  void clipboardFalso(WidgetTester tester) {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': copiado};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Future<void> abrirPixDaPrimeira(WidgetTester tester) async {
    await tester.tap(find.text('Setembro 2026'));
    await _settle(tester);
    await tester.tap(find.text('Pagar com PIX'));
    await _settle(tester);
  }

  testWidgets(
    'sheet do PIX mostra valor e vencimento; Copiar é o primário',
    (tester) async {
      telaAlta(tester);
      final adapter = _adapter();
      bool? interagiu;
      await tester.pumpWidget(
        _app(
          adapter: adapter,
          home: Consumer(
            builder:
                (context, ref, _) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () async {
                        interagiu = await mostrarPixMensalidade(
                          context: context,
                          ref: ref,
                          mensalidade: Mensalidade.fromJson(_mensalidadeJson()),
                          asAluno: true,
                        );
                      },
                      child: const Text('abrir'),
                    ),
                  ),
                ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('abrir'));
      await _settle(tester);

      expect(find.textContaining('149,90'), findsOneWidget);
      expect(find.textContaining(_truncado), findsNothing);
      expect(find.text('Vence em 10/09/2026'), findsOneWidget);

      final primario = find.byType(FxLiquidPrimaryButton);
      expect(primario, findsOneWidget);
      expect(
        tester.widget<FxLiquidPrimaryButton>(primario).label,
        'Copiar código PIX',
      );
      final secundario = find.byType(FxLiquidSecondaryButton);
      expect(secundario, findsOneWidget);
      expect(
        tester.widget<FxLiquidSecondaryButton>(secundario).label,
        'Já paguei, avisar personal',
      );
      expect(
        tester.getTopLeft(primario).dy,
        lessThan(tester.getTopLeft(secundario).dy),
      );

      await tester.tap(secundario);
      await _settle(tester);
      expect(adapter.chamadas, contains('POST $_avisoPath'));

      await tester.tap(find.text('Fechar'));
      await _settle(tester);
      expect(interagiu, isTrue);
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets(
    'mensalidades do aluno mostram centavos e recarregam após avisar',
    (tester) async {
      telaAlta(tester);
      final adapter = _adapter();
      await tester.pumpWidget(
        _app(adapter: adapter, home: const FinanceiroAlunoScreen()),
      );
      await _settle(tester);

      expect(find.textContaining('149,90'), findsWidgets);
      expect(find.textContaining(_truncado), findsNothing);
      expect(find.text('Em todas as cobranças'), findsWidgets);
      expect(adapter.listas, hasLength(1));

      await abrirPixDaPrimeira(tester);
      await tester.tap(find.byType(FxLiquidSecondaryButton).last);
      await _settle(tester);
      await tester.tap(find.text('Fechar').last);
      await _settle(tester);

      expect(adapter.listas, hasLength(2));
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('copiar o código e fechar também recarrega a lista', (
    tester,
  ) async {
    telaAlta(tester);
    clipboardFalso(tester);
    final adapter = _adapter();
    await tester.pumpWidget(
      _app(adapter: adapter, home: const FinanceiroAlunoScreen()),
    );
    await _settle(tester);
    expect(adapter.listas, hasLength(1));

    await abrirPixDaPrimeira(tester);
    await tester.tap(find.text('Copiar código PIX'));
    await _settle(tester);
    await tester.tap(find.text('Fechar').last);
    await _settle(tester);

    expect(adapter.listas, hasLength(2));
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('recarga após o PIX mantém as páginas já carregadas', (
    tester,
  ) async {
    telaAlta(tester);
    final adapter = _adapter(duasPaginas: true);
    await tester.pumpWidget(
      _app(adapter: adapter, home: const FinanceiroAlunoScreen()),
    );
    await _settle(tester);
    expect(find.text('Nas cobranças carregadas'), findsWidgets);

    await tester.tap(find.text('Carregar mais'));
    await _settle(tester);
    expect(find.text('Agosto 2026'), findsOneWidget);
    adapter.chamadas.clear();

    await abrirPixDaPrimeira(tester);
    await tester.tap(find.byType(FxLiquidSecondaryButton).last);
    await _settle(tester);
    await tester.tap(find.text('Fechar').last);
    await _settle(tester);

    expect(adapter.listas, [
      'GET $_listaPath?page=0',
      'GET $_listaPath?page=1',
    ]);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
