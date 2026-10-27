import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/screens/financeiro_mensalidade_detail_screen.dart';
import 'package:focux_app/features/financeiro/widgets/financeiro_numeros_mes.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.contatos);

  final List<Map<String, Object>> contatos;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ok = options.path.endsWith('/contatos');
    return ResponseBody.fromString(
      jsonEncode(ok ? contatos : {'erro': 'rota fora do teste'}),
      ok ? 200 : 404,
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

Widget _app(Widget home, {List<Map<String, Object>> contatos = const []}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter(contatos);
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

Mensalidade _mensalidade({String status = 'ATRASADO', String? pagoEm}) =>
    Mensalidade(
      id: 7,
      alunoId: 3,
      alunoNome: 'Hugo Souza',
      valor: '149.90',
      mesReferencia: '2026-08-01',
      vencimento: '2026-08-05',
      status: status,
      pagoEm: pagoEm,
    );

ResumoMensal _resumo({
  int recebido = 10000,
  int aberto = 25000,
  int atrasado = 30000,
  int anterior = 0,
}) => ResumoMensal(
  totalRecebido: FxMoneyFromCents.of(recebido),
  totalPrevisto: 0,
  inadimplentes: 0,
  ticketMedio: 0,
  acumuladoAnual: 0,
  totalEmAberto: FxMoneyFromCents.of(aberto),
  totalAtrasado: FxMoneyFromCents.of(atrasado),
  quantidadeAtrasadas: atrasado > 0 ? 2 : 0,
  recebidoDeMesesAnteriores: FxMoneyFromCents.of(anterior),
);

/// `FxMoney.parse` aceita a string de reais do servidor.
class FxMoneyFromCents {
  static String of(int cents) =>
      '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
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

  group('FinanceiroNumerosMes', () {
    testWidgets('mostra os três números e abre a lista do toque', (
      tester,
    ) async {
      telaAlta(tester);
      final abertos = <MensalidadeFiltro>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: FinanceiroNumerosMes(resumo: _resumo(), onAbrir: abertos.add),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('Recebido'), findsOneWidget);
      expect(find.text('A receber'), findsOneWidget);
      expect(find.text('Atrasado'), findsOneWidget);
      expect(find.text('R\$ 100,00'), findsOneWidget);
      expect(find.text('R\$ 250,00'), findsOneWidget);
      expect(find.text('R\$ 300,00'), findsOneWidget);

      await tester.tap(find.text('Recebido'));
      await tester.tap(find.text('A receber'));
      await tester.tap(find.text('Atrasado'));
      expect(abertos, [
        MensalidadeFiltro.pagas,
        MensalidadeFiltro.abertas,
        MensalidadeFiltro.atrasadas,
      ]);
    });

    testWidgets('"de meses anteriores" só aparece quando há valor', (
      tester,
    ) async {
      telaAlta(tester);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: FinanceiroNumerosMes(
              resumo: _resumo(anterior: 10000),
              onAbrir: (_) {},
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('R\$ 100,00 de meses anteriores'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: FinanceiroNumerosMes(resumo: _resumo(), onAbrir: (_) {}),
          ),
        ),
      );
      await _settle(tester);
      expect(find.textContaining('meses anteriores'), findsNothing);
    });

    for (final tela in kDynamicTypeTelas) {
      testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
        usarDynamicTypeMaximo(tester, tela);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: FinanceiroNumerosMes(
                resumo: _resumo(anterior: 10000),
                onAbrir: (_) {},
              ),
            ),
          ),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Detalhe da mensalidade', () {
    Future<void> abrir(
      WidgetTester tester,
      Mensalidade m, {
      List<Map<String, Object>> contatos = const [],
    }) async {
      await tester.pumpWidget(
        _app(
          FinanceiroMensalidadeDetailScreen(mensalidadeId: m.id, initial: m),
          contatos: contatos,
        ),
      );
      await _settle(tester);
    }

    testWidgets('atrasada: selo com dias, Cobrar e Marcar como paga', (
      tester,
    ) async {
      telaAlta(tester);
      await abrir(tester, _mensalidade());
      expect(find.text('Hugo Souza'), findsOneWidget);
      expect(find.textContaining('Atrasada há'), findsOneWidget);
      expect(find.text('R\$ 149,90'), findsOneWidget);
      expect(find.text('Cobrar'), findsOneWidget);
      expect(find.text('Marcar como paga'), findsOneWidget);
      expect(find.text('Mais ações'), findsNothing);
      expect(find.text('Cobranças feitas'), findsNothing);
      expect(find.text('Nenhum contato nesta cobrança'), findsNothing);
    });

    testWidgets('Cobrar oferece chat ou PIX copia e cola', (tester) async {
      telaAlta(tester);
      await abrir(tester, _mensalidade());
      await tester.tap(find.text('Cobrar'));
      await _settle(tester);
      expect(find.text('Como cobrar'), findsOneWidget);
      expect(find.text('Cobrar no chat'), findsOneWidget);
      expect(find.text('PIX copia e cola'), findsOneWidget);
    });

    testWidgets('menu ⋮: Cancelar vem por último, em grupo separado', (
      tester,
    ) async {
      telaAlta(tester);
      await abrir(tester, _mensalidade());
      await tester.tap(find.byTooltip('Mais opções da mensalidade'));
      await _settle(tester);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Registrar contato'), findsOneWidget);
      expect(find.text('Abrir aluno'), findsWidgets);
      expect(find.text('Cancelar mensalidade'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Cancelar mensalidade')).dy,
        greaterThan(tester.getTopLeft(find.text('Registrar contato')).dy),
      );
    });

    testWidgets('paga: sem Cobrar, com Desfazer pagamento no menu', (
      tester,
    ) async {
      telaAlta(tester);
      await abrir(
        tester,
        _mensalidade(status: 'PAGO', pagoEm: '2026-08-12T09:00:00'),
      );
      expect(find.text('Paga em 12/08'), findsOneWidget);
      expect(find.text('Cobrar'), findsNothing);
      expect(find.text('Marcar como paga'), findsNothing);
      await tester.tap(find.byTooltip('Mais opções da mensalidade'));
      await _settle(tester);
      expect(find.text('Cancelar mensalidade'), findsNothing);
      expect(find.text('Desfazer pagamento'), findsOneWidget);
    });

    testWidgets('lista as cobranças feitas só quando existem', (tester) async {
      telaAlta(tester);
      await abrir(
        tester,
        _mensalidade(),
        contatos: [
          {
            'id': 1,
            'tipo': 'WHATSAPP',
            'observacao': 'Vai pagar sexta',
            'registradoEm': '2026-08-20T10:00:00',
          },
        ],
      );
      expect(find.text('Cobranças feitas'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    for (final tela in kDynamicTypeTelas) {
      testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
        usarDynamicTypeMaximo(tester, tela);
        await abrir(tester, _mensalidade());
        final ex = tester.takeException();
        expect(ex, isNull, reason: ex?.toString());
        expect(find.text('Marcar como paga'), findsOneWidget);
      });
    }
  });
}
