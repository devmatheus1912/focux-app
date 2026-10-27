import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/dunning/screens/dunning_ops_screen.dart';
import 'package:focux_app/features/dunning/utils/dunning_ops_display.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';
import '../../support/riverpod_seeds.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.home);

  final Map<String, Object> home;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ok = options.path == '/api/dunning/home';
    return ResponseBody.fromString(
      jsonEncode(ok ? home : {'erro': 'rota fora do teste'}),
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

Map<String, Object> _home(List<Map<String, Object?>> falhas) => {
  'snapshot': {
    'total': falhas.length,
    'abertas': falhas.length,
    'recuperadas': 0,
    'recoveryRate': 0,
  },
  'falhas': falhas,
  'page': 0,
  'size': 20,
  'hasMore': false,
};

Map<String, Object?> _falha(
  int id,
  String contexto, {
  int? alunoId,
  String? alunoNome,
}) => {
  'id': id,
  'alunoId': alunoId,
  'alunoNome': alunoNome,
  'contexto': contexto,
  'motivo': 'cartao_recusado',
  'valor': '100.00',
  'tentativa': 1,
};

Widget _app(Map<String, Object> home) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter(home);
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => const DunningOpsScreen())],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
      seededPlanoFeatures(PlanoFeatures.optimisticEnterprise),
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

  test('dunningSeparar: assinatura do personal nunca vira falha de aluno', () {
    final r = dunningSeparar<Map<String, Object?>>(
      [
        _falha(1, 'ALUNO_MENSALIDADE', alunoId: 3, alunoNome: 'Beto'),
        _falha(2, 'FOCUX_SUBSCRIPTION'),
        _falha(3, 'FOCUX_SUBSCRIPTION', alunoId: 7, alunoNome: 'Cris'),
      ],
      contexto: (f) => f['contexto'] as String,
      alunoId: (f) => f['alunoId'] as int?,
    );
    expect(r.alunos.map((f) => f['id']), [1, 3]);
    expect(r.assinatura.map((f) => f['id']), [2]);
  });

  testWidgets('vazio explica a rotina e leva às mensalidades atrasadas', (
    tester,
  ) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_home(const [])));
    await _settle(tester);
    expect(find.text('Tudo em dia'), findsOneWidget);
    expect(find.textContaining('6h10'), findsOneWidget);
    expect(find.text('Ver mensalidades atrasadas'), findsOneWidget);
    expect(find.text('Saúde da base'), findsNothing);
    expect(find.text('Alunos em risco'), findsNothing);
  });

  testWidgets('blocos separados: alunos × assinatura Focux', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(
      _app(
        _home([
          _falha(1, 'ALUNO_MENSALIDADE', alunoId: 3, alunoNome: 'Beto'),
          _falha(2, 'FOCUX_SUBSCRIPTION'),
        ]),
      ),
    );
    await _settle(tester);
    expect(find.text('Mensalidades dos alunos'), findsOneWidget);
    expect(find.text('Sua assinatura Focux'), findsOneWidget);
    expect(find.text('Beto'), findsWidgets);
    final alunos = tester.getTopLeft(find.text('Mensalidades dos alunos')).dy;
    final assin = tester.getTopLeft(find.text('Sua assinatura Focux')).dy;
    expect(assin, greaterThan(alunos));
    expect(find.text('Saúde da base'), findsNothing);
  });

  testWidgets('só a assinatura: não existe bloco de alunos', (tester) async {
    telaAlta(tester);
    await tester.pumpWidget(_app(_home([_falha(2, 'FOCUX_SUBSCRIPTION')])));
    await _settle(tester);
    expect(find.text('Mensalidades dos alunos'), findsNothing);
    expect(find.text('Sua assinatura Focux'), findsOneWidget);
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(tela)}', (tester) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.pumpWidget(
        _app(
          _home([
            _falha(1, 'ALUNO_MENSALIDADE', alunoId: 3, alunoNome: 'Beto'),
            _falha(2, 'FOCUX_SUBSCRIPTION'),
          ]),
        ),
      );
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }
}
