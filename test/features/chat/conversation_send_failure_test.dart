import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/chat/screens/conversation_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _historico = '/api/chat/aluno/historico/page';
const _enviar = '/api/chat/aluno/enviar';
const _texto = 'Posso trocar o treino de amanhã?';

class _ChatAdapter implements HttpClientAdapter {
  int falhasRestantes = 0;
  final List<Map<String, dynamic>> envios = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == _historico) {
      return _json({'items': <Object>[], 'hasMore': false}, 200);
    }
    if (options.method == 'POST' && options.path == _enviar) {
      final body = Map<String, dynamic>.from(options.data as Map);
      envios.add(body);
      if (falhasRestantes > 0) {
        falhasRestantes--;
        return _json({'erro': 'Serviço fora do ar'}, 503);
      }
      return _json({
        'id': 99,
        'remetente': 'ALUNO',
        'conteudo': body['conteudo'],
        'enviadoEm': DateTime.now().toIso8601String(),
        'tipoMidia': 'TEXTO',
        'clientMessageId': body['clientMessageId'],
      }, 200);
    }
    return _json({'ok': true}, 200);
  }

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
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

Widget _app(_ChatAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ConversationScreen.aluno()),
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _enviarTexto(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), _texto);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
  await _settle(tester);
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

  void pluginsMudos(WidgetTester tester) {
    const canais = [
      MethodChannel('com.llfbandit.record/messages'),
      SystemChannels.platform,
    ];
    for (final canal in canais) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        canal,
        (_) async => null,
      );
    }
    addTearDown(() {
      for (final canal in canais) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          canal,
          null,
        );
      }
    });
  }

  testWidgets(
    'envio que falha mantém o texto como "Não enviada" e reenvia com o mesmo id',
    (tester) async {
      telaAlta(tester);
      pluginsMudos(tester);
      final adapter = _ChatAdapter()..falhasRestantes = 1;
      await tester.pumpWidget(_app(adapter));
      await _settle(tester);

      await _enviarTexto(tester);

      expect(find.text(_texto), findsOneWidget);
      expect(find.text('Não enviada'), findsOneWidget);
      expect(find.text('Enviado'), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await _settle(tester);

      expect(adapter.envios, hasLength(2));
      expect(
        adapter.envios.last['clientMessageId'],
        adapter.envios.first['clientMessageId'],
      );
      expect(find.text(_texto), findsOneWidget);
      expect(find.text('Não enviada'), findsNothing);
      expect(find.text('Enviado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('digitar o mesmo texto de novo reenvia a bolha não enviada', (
    tester,
  ) async {
    telaAlta(tester);
    pluginsMudos(tester);
    final adapter = _ChatAdapter()..falhasRestantes = 1;
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);

    await _enviarTexto(tester);
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    await _enviarTexto(tester);

    expect(adapter.envios, hasLength(2));
    expect(
      adapter.envios.last['clientMessageId'],
      adapter.envios.first['clientMessageId'],
    );
    expect(find.text(_texto), findsOneWidget);
    expect(find.text('Mensagem recente já enviada.'), findsNothing);
    expect(find.text('Enviado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Apagar tira só a bolha local, sem chamar o servidor', (
    tester,
  ) async {
    telaAlta(tester);
    pluginsMudos(tester);
    final adapter = _ChatAdapter()..falhasRestantes = 1;
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);

    await _enviarTexto(tester);
    await tester.tap(find.text('Apagar'));
    await _settle(tester);

    expect(find.text(_texto), findsNothing);
    expect(find.text('Não enviada'), findsNothing);
    expect(adapter.envios, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('envio com sucesso não mostra estado de falha', (tester) async {
    telaAlta(tester);
    pluginsMudos(tester);
    final adapter = _ChatAdapter();
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);

    await _enviarTexto(tester);

    expect(find.text(_texto), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Não enviada'), findsNothing);
    expect(adapter.envios, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
  });
}
