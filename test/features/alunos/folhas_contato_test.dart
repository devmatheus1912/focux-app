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
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  void tela(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('Follow-up', () {
    Future<_Adapter> abrir(WidgetTester tester, {Aluno? aluno}) async {
      tela(tester);
      final adapter = _Adapter();
      await tester.pumpWidget(
        _app(
          adapter,
          (c) => TextButton(
            onPressed:
                () => showAluno360CommitmentSheet(c, aluno: aluno ?? _hugo()),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await _settle(tester);
      return adapter;
    }

    testWidgets('estado em linhas, atalhos de data e "Contato feito" fixo', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('Último contato'), findsOneWidget);
      expect(find.text('Próximo contato'), findsOneWidget);
      expect(find.text('Sem data'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);
      expect(find.text('Em 3 dias'), findsOneWidget);
      expect(find.text('Em 1 semana'), findsOneWidget);
      expect(find.text('Escolher data'), findsOneWidget);
      expect(find.text('Contato feito'), findsOneWidget);
      // o texto solto antigo e os botões vazados saíram
      expect(find.textContaining('sincronizado com a nuvem'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(
        find.text('Limpar follow-up'),
        findsNothing,
      ); // sem data, nada a limpar
    });

    testWidgets('um atalho grava a data (sem abrir outra folha)', (
      tester,
    ) async {
      final adapter = await abrir(tester);
      await tester.tap(find.text('Em 3 dias'));
      await _settle(tester);
      final patch = adapter.chamadas.firstWhere(
        (c) => c.metodo == 'PATCH' && c.path == '/api/alunos/3/follow-up',
      );
      final esperado = DateTime.now().add(const Duration(days: 3));
      final iso =
          '${esperado.year.toString().padLeft(4, '0')}-'
          '${esperado.month.toString().padLeft(2, '0')}-'
          '${esperado.day.toString().padLeft(2, '0')}';
      expect((patch.corpo as Map)['proximoContato'], iso);
    });

    testWidgets('com data: aparece "Limpar follow-up" em vermelho e o valor', (
      tester,
    ) async {
      final data = DateTime.now().add(const Duration(days: 10));
      final iso =
          '${data.year.toString().padLeft(4, '0')}-'
          '${data.month.toString().padLeft(2, '0')}-'
          '${data.day.toString().padLeft(2, '0')}';
      await abrir(tester, aluno: _hugo(proximo: iso));
      expect(find.text('Sem data'), findsNothing);
      expect(find.text('Limpar follow-up'), findsOneWidget);
    });

    testWidgets('"Contato feito" registra o contato', (tester) async {
      final adapter = await abrir(tester);
      await tester.tap(find.text('Contato feito'));
      await _settle(tester);
      expect(
        adapter.chamadas.any(
          (c) =>
              c.metodo == 'POST' && c.path == '/api/alunos/3/contato-realizado',
        ),
        isTrue,
      );
    });
  });

  group('Mensagem sugerida', () {
    Future<void> abrir(WidgetTester tester, [_Adapter? adapter]) async {
      tela(tester);
      await tester.pumpWidget(
        _app(
          adapter ?? _Adapter(),
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
        ),
      );
      await tester.tap(find.text('abrir'));
      await _settle(tester);
    }

    testWidgets(
      'mensagem em cartão, "Abrir chat" principal, o resto em texto',
      (tester) async {
        await abrir(tester);
        expect(find.text('Mensagem sugerida'), findsOneWidget);
        expect(find.text('Para Hugo'), findsOneWidget);
        expect(find.text('Hugo, completar mapa corporal'), findsOneWidget);
        expect(find.text('Abrir chat'), findsOneWidget);
        expect(find.text('Copiar mensagem'), findsOneWidget);
        expect(find.text('Contato feito'), findsOneWidget);
        // só um botão cheio na folha
        expect(find.byType(FilledButton), findsNothing);
      },
    );

    testWidgets('"Contato feito" fecha e registra', (tester) async {
      final adapter = _Adapter();
      await abrir(tester, adapter);
      await tester.tap(find.text('Contato feito'));
      await _settle(tester);
      expect(
        adapter.chamadas.any(
          (c) => c.path == '/api/alunos/3/contato-realizado',
        ),
        isTrue,
      );
      expect(find.text('Mensagem sugerida'), findsNothing);
    });

    testWidgets('aguenta fonte 1.3 e 2.0 sem estourar', (tester) async {
      for (final escala in [1.3, 2.0]) {
        tester.view.physicalSize = const Size(360, 690);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          _app(
            _Adapter(),
            (c) => TextButton(
              onPressed:
                  () => showAlunoOutreachMessageSheet(
                    c,
                    alunoId: 3,
                    alunoNome: 'Hugo',
                    message:
                        'Hugo, completar mapa corporal e enviar as fotos de hoje',
                  ),
              child: const Text('abrir'),
            ),
          ),
        );
        await tester.tap(find.text('abrir'));
        await _settle(tester);
        final ex = tester.takeException();
        expect(ex, isNull, reason: 'escala $escala: ${ex ?? ''}');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
