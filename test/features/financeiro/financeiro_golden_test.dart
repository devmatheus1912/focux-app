@Tags(['golden'])
library;

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

import '../../support/tolerant_golden_comparator.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(<dynamic>[]),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

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

Widget _app(Widget home, {required bool dark, double scale = 1.0}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter();
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: EagleTokens.brandAccent,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

ResumoMensal _resumo() => ResumoMensal(
  totalRecebido: '1250.00',
  totalPrevisto: '2000.00',
  inadimplentes: 2,
  ticketMedio: '250.00',
  acumuladoAnual: '9000.00',
  totalEmAberto: '450.00',
  totalAtrasado: '300.00',
  quantidadeAtrasadas: 2,
  recebidoDeMesesAnteriores: '200.00',
);

final _atrasada = Mensalidade(
  id: 7,
  alunoId: 3,
  alunoNome: 'Hugo Souza',
  valor: '149.90',
  mesReferencia: '2026-08-01',
  vencimento: '2026-08-05',
  status: 'ATRASADO',
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Future<void> detalhe(
    WidgetTester tester, {
    required bool dark,
    double scale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        FinanceiroMensalidadeDetailScreen(mensalidadeId: 7, initial: _atrasada),
        dark: dark,
        scale: scale,
      ),
    );
    await _settle(tester);
  }

  testWidgets('detalhe da mensalidade atrasada (claro)', (tester) async {
    await detalhe(tester, dark: false);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/financeiro_detalhe_atrasada_390.png',
    );
  });

  testWidgets('detalhe da mensalidade atrasada (escuro)', (tester) async {
    await detalhe(tester, dark: true);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/financeiro_detalhe_atrasada_390_dark.png',
    );
  });

  testWidgets('detalhe da mensalidade atrasada (fonte 1.3)', (tester) async {
    await detalhe(tester, dark: false, scale: 1.3);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/financeiro_detalhe_atrasada_390_scale13.png',
    );
  });

  Future<void> numeros(WidgetTester tester, {required bool dark}) async {
    await tester.binding.setSurfaceSize(const Size(390, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FinanceiroNumerosMes(resumo: _resumo(), onAbrir: (_) {}),
          ),
        ),
        dark: dark,
      ),
    );
    await _settle(tester);
  }

  testWidgets('números do mês (claro)', (tester) async {
    await numeros(tester, dark: false);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/financeiro_numeros_mes_390.png',
    );
  });

  testWidgets('números do mês (escuro)', (tester) async {
    await numeros(tester, dark: true);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/financeiro_numeros_mes_390_dark.png',
    );
  });
}
