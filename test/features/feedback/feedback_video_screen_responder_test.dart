import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/feedback/screens/feedback_video_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class _Adapter implements HttpClientAdapter {
  final chamadas = <String>[];
  final corpos = <String, Object?>{};
  var respondido = false;

  Map<String, Object?> _item() => {
    'id': 1,
    'alunoId': 7,
    'personalId': 5,
    'exercicioId': 10,
    'exercicioNome': 'Puxada alta',
    'videoUrl': 'https://cdn.example.test/v.mp4',
    'comentario': 'senti a lombar',
    'criadoEm': '2026-10-01T21:26:14',
    'respostaPersonal': respondido ? 'Desça devagar' : null,
    'status': respondido ? 'RESPONDIDO' : 'ENVIADO',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chave = '${options.method} ${options.path}';
    chamadas.add(chave);
    corpos[chave] = options.data;
    Object body;
    if (chave == 'PUT /api/feedback-videos/1/resposta') {
      respondido = true;
      body = _item();
    } else {
      body = {
        'content': [_item()],
        'hasNext': false,
        'page': 0,
        'size': 20,
        'totalElements': 1,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('personal responde e a resposta vai para o backend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
        child: MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const FeedbackVideoScreen(alunoId: 7, alunoNome: 'Aluno'),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Novo feedback'), findsNothing);
    await tester.tap(find.textContaining('Puxada').first);
    await _settle(tester);
    expect(find.textContaining('Assistir'), findsOneWidget);
    expect(find.text('Aluno: "senti a lombar"'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Desça devagar');
    await tester.tap(find.text('Enviar ao aluno'));
    await _settle(tester);

    expect(adapter.chamadas, contains('PUT /api/feedback-videos/1/resposta'));
    expect(adapter.corpos['PUT /api/feedback-videos/1/resposta'], {
      'resposta': 'Desça devagar',
    });
    expect(find.text('Respondido'), findsOneWidget);
  });

  testWidgets('segurar abre as ações com Remover', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _Adapter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
        child: MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const FeedbackVideoScreen(alunoId: 7, alunoNome: 'Aluno'),
        ),
      ),
    );
    await _settle(tester);
    await tester.longPress(find.textContaining('Puxada').first);
    await _settle(tester);
    expect(find.text('Remover'), findsOneWidget);
    expect(find.text('Responder'), findsOneWidget);
  });
}
