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
import 'package:focux_app/features/chat/utils/chat_outbox.dart';
import 'package:focux_app/features/chat/widgets/conversation_outgoing_status.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

const _historico = '/api/chat/aluno/historico/page';
const _enviar = '/api/chat/aluno/enviar';
const _texto = 'Posso trocar o treino de amanhã?';

class _ChatAdapter implements HttpClientAdapter {
  int falhasRestantes = 0;
  int conflitosRestantes = 0;
  int recusasRestantes = 0;
  final List<Map<String, dynamic>> envios = [];
  final List<Map<String, dynamic>> extras = [];

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
      extras.add(Map.of(options.extra));
      if (recusasRestantes > 0) {
        recusasRestantes--;
        return _json({'erro': 'Plano não inclui chat'}, 403);
      }
      if (conflitosRestantes > 0) {
        conflitosRestantes--;
        return _json({'error': 'Requisicao em processamento.'}, 409);
      }
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
      final clientId = adapter.envios.first['clientMessageId'];
      expect(adapter.envios.last['clientMessageId'], clientId);
      final chave = ApiClient.idempotent(chatIdempotencyScope(clientId)).extra;
      expect(adapter.extras, [chave, chave]);
      expect(find.text(_texto), findsOneWidget);
      expect(find.text('Não enviada'), findsNothing);
      expect(find.text('Enviado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('403 do servidor: reenvio manual usa chave nova e o mesmo id', (
    tester,
  ) async {
    telaAlta(tester);
    pluginsMudos(tester);
    final adapter = _ChatAdapter()..recusasRestantes = 1;
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);

    await _enviarTexto(tester);
    expect(find.text('Não enviada'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await _settle(tester);

    expect(adapter.envios, hasLength(2));
    final clientId = adapter.envios.first['clientMessageId'];
    expect(adapter.envios.last['clientMessageId'], clientId);
    expect(
      adapter.extras.first,
      ApiClient.idempotent(chatIdempotencyScope(clientId)).extra,
    );
    expect(adapter.extras.last, isNot(adapter.extras.first));
    expect(find.text('Enviado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
    '409 da primeira tentativa em processamento segue "Enviando…" e confirma',
    (tester) async {
      telaAlta(tester);
      pluginsMudos(tester);
      final adapter = _ChatAdapter()..conflitosRestantes = 1;
      await tester.pumpWidget(_app(adapter));
      await _settle(tester);

      await _enviarTexto(tester);

      expect(find.text('Enviando…'), findsOneWidget);
      expect(find.text('Não enviada'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);

      expect(adapter.envios, hasLength(2));
      expect(
        adapter.envios.last['clientMessageId'],
        adapter.envios.first['clientMessageId'],
      );
      expect(find.text('Enviado'), findsOneWidget);
      expect(find.text('Não enviada'), findsNothing);
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

  testWidgets('Descartar tira só a bolha local, sem chamar o servidor', (
    tester,
  ) async {
    telaAlta(tester);
    pluginsMudos(tester);
    final adapter = _ChatAdapter()..falhasRestantes = 1;
    await tester.pumpWidget(_app(adapter));
    await _settle(tester);

    await _enviarTexto(tester);
    await tester.tap(find.text('Descartar'));
    await _settle(tester);

    expect(find.text(_texto), findsNothing);
    expect(find.text('Não enviada'), findsNothing);
    expect(adapter.envios, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('"Não enviada" usa badInk no claro e badDark no escuro', (
    tester,
  ) async {
    Future<Color?> corNo(Brightness brilho) async {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(brilho),
          theme: ThemeData(brightness: brilho),
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const Scaffold(
            body: ConversationDeliveryStatus(
              status: ChatOutgoingStatus.failed,
              color: Colors.grey,
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.text('Não enviada')).style?.color;
    }

    expect(await corNo(Brightness.light), EagleTokens.badInk);
    expect(await corNo(Brightness.dark), EagleTokens.badDark);
  });

  testWidgets('reenvio desabilitado explica por quê ao leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: ConversationSendFailedActions(
            accentColor: EagleTokens.brandAccent,
            onRetry: null,
            onDiscard: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSemantics(find.text('Tentar novamente')),
      isSemantics(
        isButton: true,
        isEnabled: false,
        hint: 'Disponível quando o anexo em envio terminar',
      ),
    );
    semantics.dispose();
  });

  testWidgets('ações da não enviada quebram linha com texto grande', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: ConversationSendFailedActions(
                  accentColor: EagleTokens.brandAccent,
                  onRetry: () {},
                  onDiscard: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final reenviar = tester.getRect(find.text('Tentar novamente'));
    final descartar = tester.getRect(find.text('Descartar'));
    expect(descartar.top, greaterThanOrEqualTo(reenviar.bottom));
  });

  testWidgets('reenvio sem ação (outro anexo subindo) aparece desabilitado', (
    tester,
  ) async {
    var descartou = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Scaffold(
          body: ConversationSendFailedActions(
            accentColor: EagleTokens.brandAccent,
            onRetry: null,
            onDiscard: () => descartou = true,
          ),
        ),
      ),
    );
    await tester.pump();

    final botoes = find.byWidgetPredicate((w) => w is TextButton);
    expect(botoes, findsNWidgets(2));
    final reenviar = tester.widget<TextButton>(botoes.first);
    expect(reenviar.onPressed, isNull);
    for (final e in botoes.evaluate()) {
      final size = tester.getSize(find.byWidget(e.widget));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.text('Descartar'));
    expect(descartou, isTrue);
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('campo e enviar do chat aguentam ${descreverTela(tela)}', (
      tester,
    ) async {
      usarDynamicTypeMaximo(tester, tela);
      pluginsMudos(tester);
      await tester.pumpWidget(_app(_ChatAdapter()..falhasRestantes = 1));
      await _settle(tester);

      await _enviarTexto(tester);
      expect(find.text('Não enviada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });
  }

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
