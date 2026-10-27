import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/winback/screens/winback_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'content': <dynamic>[],
        'page': 0,
        'hasNext': false,
        'totalElements': 0,
      }),
      200,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('vazio explica o aviso automático e volta para Alunos em risco', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _Adapter();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const WinbackScreen()),
        GoRoute(
          path: '/retencao',
          builder: (_, _) => const Scaffold(body: Text('EM RISCO')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
        child: MaterialApp.router(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: EagleTokens.brandAccent,
            ),
            useMaterial3: true,
          ),
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Histórico de retomada'), findsWidgets);
    expect(find.text('Nenhum envio ainda'), findsOneWidget);
    expect(
      find.textContaining('o Focux manda um aviso automático'),
      findsOneWidget,
    );
    expect(find.text('Saúde da base'), findsNothing);
    await tester.tap(find.text('Ver alunos em risco'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('EM RISCO'), findsOneWidget);
  });
}
