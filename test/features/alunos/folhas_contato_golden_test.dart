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
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_commitment_sheet.dart';
import 'package:focux_app/features/alunos/widgets/aluno_outreach_message_sheet.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import '../../support/tolerant_golden_comparator.dart';
import 'package:google_fonts/google_fonts.dart';

class _Chamada {
  _Chamada(this.metodo, this.path, this.corpo);

  final String metodo;
  final String path;
  final Object? corpo;
}

class _Adapter implements HttpClientAdapter {
  final List<_Chamada> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(_Chamada(options.method, options.path, options.data));
    return ResponseBody.fromString(
      jsonEncode({
        'id': 3,
        'nome': 'Hugo',
        'email': 'h@test.com',
        'status': 'ATIVO',
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

Widget _app(_Adapter adapter, Widget Function(BuildContext) abrir) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
        useMaterial3: true,
      ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: Builder(builder: (c) => Center(child: abrir(c)))),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Aluno _hugo({String? proximo}) => Aluno(
  id: 3,
  nome: 'Hugo',
  email: 'h@test.com',
  status: 'ATIVO',
  proximoContato: proximo,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Future<void> abrir(
    WidgetTester tester,
    Widget Function(BuildContext) botao,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_Adapter(), botao));
    await tester.tap(find.text('abrir'));
    await _settle(tester);
  }

  testWidgets('Follow-up', (tester) async {
    await abrir(
      tester,
      (c) => TextButton(
        onPressed: () => showAluno360CommitmentSheet(c, aluno: _hugo()),
        child: const Text('abrir'),
      ),
    );
    await expectFocuxGolden(find.byType(MaterialApp), 'goldens/folha_followup_390.png');
  });

  testWidgets('Mensagem sugerida', (tester) async {
    await abrir(
      tester,
      (c) => TextButton(
        onPressed:
            () => showAlunoOutreachMessageSheet(
              c,
              alunoId: 3,
              alunoNome: 'Hugo',
              message: 'Hugo, completar mapa corporal',
            ),
        child: const Text('abrir'),
      ),
    );
    await expectFocuxGolden(find.byType(MaterialApp), 'goldens/folha_mensagem_390.png');
  });
}
