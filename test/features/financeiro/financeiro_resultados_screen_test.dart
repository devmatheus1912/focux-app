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
import 'package:focux_app/features/financeiro/financeiro_hub_scope.dart';
import 'package:focux_app/features/financeiro/screens/financeiro_resultados_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.resumo, this.coorte});

  final Map<String, Object> resumo;

  /// Nulo = o servidor nega (plano sem relatórios).
  final Map<String, Object>? coorte;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    var status = 200;
    switch (options.path) {
      case '/api/financeiro/home':
        body = {
          'dashboard': {
            'receitaMes': '500.00',
            'receitaAcumulada': '5000.00',
            'ticketMedio': '100.00',
            'totalInadimplentes': 0,
            'previsaoReceita': '600.00',
            'vencimentosProximos': <dynamic>[],
            'topAlunos': [
              {'alunoId': 3, 'alunoNome': 'Beto', 'totalPago': '900.00'},
            ],
            'evolucaoMensal': [
              {'mes': '2026-09', 'recebido': '400.00'},
              {'mes': '2026-10', 'recebido': '500.00'},
            ],
          },
          'mensalidades': <dynamic>[],
          'resumoMesAtual': resumo,
        };
      case '/api/financeiro/mensalidades/resumo-mensal':
        body = {
          'totalRecebido': '0.00',
          'totalPrevisto': '250.00',
          'inadimplentes': 0,
          'ticketMedio': '0',
          'acumuladoAnual': '0',
        };
      case '/api/relatorio/business':
        if (coorte == null) {
          status = 403;
          body = {'erro': 'plano'};
        } else {
          body = coorte;
        }
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? {'erro': 'rota fora do teste'}),
      body == null ? 404 : status,
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

Map<String, Object> _resumo({
  String recebido = '500.00',
  String previsto = '600.00',
  String aberto = '100.00',
  String atrasado = '0.00',
  int atrasadas = 0,
  String anterior = '0.00',
}) => {
  'totalRecebido': recebido,
  'totalPrevisto': previsto,
  'inadimplentes': atrasadas,
  'ticketMedio': '100.00',
  'acumuladoAnual': '5000.00',
  'totalEmAberto': aberto,
  'totalAtrasado': atrasado,
  'quantidadeAtrasadas': atrasadas,
  'recebidoDeMesesAnteriores': anterior,
};

Map<String, Object> _coorte({required int pagantes, required int meses}) => {
  'mrrAtual': '500.00',
  'mrrAnterior': '400.00',
  'mrrPrevisto': '600.00',
  'ndrPct': 0.0,
  'arpa': '0.00',
  'ltvProxy': '0.00',
  'alunosAtivos': pagantes,
  'alunosTotal': pagantes,
  'inadimplentes': 0,
  'dunningRecoveryPct': 0.0,
  'dunningAbertas': 0,
  'pqlScore': 95,
  'pqlClassificacao': 'PRIORIDADE',
  'alunosPagantes': pagantes,
  'churnPct': 100.0,
  'vidaMediaMeses': 1.0,
  'mesesComCobranca': meses,
};

Widget _app(_Adapter adapter, {void Function(MensalidadeFiltro)? onFiltro}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder:
            (_, _) => Scaffold(
              body: FinanceiroHubScope(
                goToMensalidades: ({String source = ''}) {},
                openNovaMensalidade: ({String source = ''}) {},
                openFiltro: onFiltro ?? (_) {},
                child: const FinanceiroResultadosScreen(),
              ),
            ),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('poucos dados: sem Detalhes, sem 0,0% e sem alarme', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(
      _app(_Adapter(resumo: _resumo(), coorte: _coorte(pagantes: 5, meses: 1))),
    );
    await _settle(tester);
    expect(find.text('Quanto entrou'), findsOneWidget);
    expect(find.text('de R\$ 600 lançados'), findsOneWidget);
    expect(find.text('Quem atrasa'), findsOneWidget);
    expect(
      find.text(
        'Ainda há poucos dados para estes números. Eles aparecem com 10 alunos pagantes e 3 meses de cobrança.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ver detalhes'), findsNothing);
    expect(find.text('RECEITA MANTIDA'), findsNothing);
    expect(find.textContaining('0,0%'), findsNothing);
    expect(find.textContaining('100,0%'), findsNothing);
    // jargão e blocos que saíram
    for (final sigla in ['NDR', 'ARPA', 'LTV', 'Ativação', 'Recuperação']) {
      expect(find.textContaining(sigla), findsNothing, reason: sigla);
    }
  });

  testWidgets(
    'dados suficientes: Detalhes recolhido, abre e explica em português',
    (tester) async {
      telaAlta(tester);
      await tester.pumpWidget(
        _app(
          _Adapter(resumo: _resumo(), coorte: _coorte(pagantes: 12, meses: 4)),
        ),
      );
      await _settle(tester);
      expect(find.text('RECEITA MANTIDA'), findsNothing); // recolhido
      expect(find.text('Ver detalhes'), findsOneWidget);
      await tester.tap(find.text('Ver detalhes'));
      await _settle(tester);
      expect(find.text('RECEITA MANTIDA'), findsOneWidget);
      expect(find.text('MÉDIA POR ALUNO PAGANTE'), findsOneWidget);
      expect(find.text('QUANTO UM ALUNO VALE EM MÉDIA'), findsOneWidget);
      expect(find.text('ALUNOS QUE PARARAM DE PAGAR'), findsOneWidget);
      expect(find.text('Esconder detalhes'), findsOneWidget);
    },
  );

  testWidgets('sem acesso à coorte (plano): a seção Detalhes não existe', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(resumo: _resumo())));
    await _settle(tester);
    expect(find.text('Detalhes'), findsNothing);
    expect(find.text('Quanto entrou'), findsOneWidget);
  });

  testWidgets('recebido maior que lançado tem a explicação na própria tela', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(
      _app(
        _Adapter(
          resumo: _resumo(
            recebido: '100.00',
            previsto: '0.00',
            aberto: '0.00',
            anterior: '100.00',
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(
      find.textContaining('O recebido conta pela data do pagamento'),
      findsOneWidget,
    );
    expect(find.text('R\$ 100 de meses anteriores'), findsOneWidget);
  });

  testWidgets('recebido menor que lançado não precisa de explicação', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(resumo: _resumo())));
    await _settle(tester);
    expect(
      find.textContaining('O recebido conta pela data do pagamento'),
      findsNothing,
    );
    expect(find.text('R\$ 100 a receber'), findsOneWidget);
  });

  testWidgets('Quem atrasa abre a lista de atrasadas', (tester) async {
    telaAlta(tester);
    final filtros = <MensalidadeFiltro>[];
    await tester.pumpWidget(
      _app(
        _Adapter(resumo: _resumo(atrasado: '300.00', atrasadas: 2)),
        onFiltro: filtros.add,
      ),
    );
    await _settle(tester);
    expect(find.textContaining('2 alunos'), findsOneWidget);
    await tester.tap(find.text('Quem atrasa'));
    await _settle(tester);
    expect(filtros, [MensalidadeFiltro.atrasadas]);
  });

  testWidgets('sem ninguém atrasado: "Ninguém atrasado", sem cor de alarme', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(resumo: _resumo())));
    await _settle(tester);
    expect(find.text('Ninguém atrasado'), findsOneWidget);
  });

  testWidgets('trocar o mês carrega o resumo daquele mês', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_Adapter(resumo: _resumo())));
    await _settle(tester);
    final agora = DateTime.now();
    final anterior = DateTime(agora.year, agora.month - 1, 1);
    const meses = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    await tester.tap(find.text('${meses[agora.month]} ${agora.year}'));
    await _settle(tester);
    await tester.tap(find.text('${meses[anterior.month]} ${anterior.year}'));
    await _settle(tester);
    expect(find.text('de R\$ 250 lançados'), findsOneWidget);
    // a coorte é do mês atual: some ao olhar outro mês
    expect(find.text('Detalhes'), findsNothing);
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.pumpWidget(
        _app(
          _Adapter(
            resumo: _resumo(
              recebido: '12345.00',
              previsto: '1000.00',
              atrasado: '8888.00',
              atrasadas: 12,
              anterior: '5000.00',
            ),
            coorte: _coorte(pagantes: 12, meses: 4),
          ),
        ),
      );
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }
}
