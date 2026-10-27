import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/screens/add_exercicio_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/dynamic_type_harness.dart';

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
      jsonEncode({'id': 55, 'nome': 'Novo'}),
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

Widget _app(_Adapter adapter, {Exercicio? copiaDe}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/novo',
    routes: [
      GoRoute(
        path: '/novo',
        builder: (_, _) => AddExercicioScreen(copiaDe: copiaDe),
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

final _orientacao = find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? '').toLowerCase().contains('orientação · opcional'),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  void tela(WidgetTester tester) {
    tester.view.physicalSize = const Size(1290, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'formulário vazio: rótulos sempre visíveis e obrigatórios marcados',
    (tester) async {
      tela(tester);
      await tester.pumpWidget(_app(_Adapter()));
      await _settle(tester);
      expect(find.text('Nome do exercício'), findsOneWidget);
      expect(find.text('obrigatório'), findsOneWidget);
      // grupo principal sem valor: rótulo + "Escolher · obrigatório"
      expect(find.text('Grupo principal'), findsOneWidget);
      expect(find.text('Escolher · obrigatório'), findsOneWidget);
      // valores já escolhidos continuam com o rótulo ao lado
      expect(find.text('Modalidade'), findsOneWidget);
      expect(find.text('Musculação'), findsOneWidget);
      expect(find.text('Dificuldade'), findsOneWidget);
      expect(find.text('Iniciante'), findsOneWidget);
    },
  );

  testWidgets(
    '"Tipo de exercício" explica o que preenche; Orientação é opcional e recolhida',
    (tester) async {
      tela(tester);
      await tester.pumpWidget(_app(_Adapter()));
      await _settle(tester);
      expect(find.text('Tipo de exercício'), findsOneWidget);
      expect(find.text('Perfil rápido'), findsNothing);
      expect(
        find.text('Preenche equipamentos e espaços para você ajustar.'),
        findsOneWidget,
      );
      expect(_orientacao, findsOneWidget);
      expect(find.text('Recolher campos'), findsNothing);
      expect(find.text('Descrição curta'), findsNothing);
      await tester.ensureVisible(find.text('Adicionar orientação'));
      await tester.tap(find.text('Adicionar orientação'));
      await _settle(tester);
      expect(find.text('Descrição curta'), findsOneWidget);
      expect(find.text('Orientação ao aluno'), findsOneWidget);
    },
  );

  testWidgets('vídeo na criação é opcional e fica antes da Orientação', (
    tester,
  ) async {
    tela(tester);
    await tester.pumpWidget(_app(_Adapter()));
    await _settle(tester);
    expect(find.text('Adicionar meu vídeo'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Adicionar meu vídeo')).dy,
      lessThan(tester.getTopLeft(_orientacao).dy),
    );
  });

  group('a partir da biblioteca Focux', () {
    final original = Exercicio.fromJson({
      'id': 9,
      'nome': 'Supino reto',
      'curado': true,
      'videoSource': 'FOCUX_LIBRARY',
      'videoUrl': 'https://cdn.test/oficial.mp4',
      'grupoMuscularPrimario': 'PEITO',
      'descricao': 'Empurre a barra.',
    });

    testWidgets('vem preenchido, com "(meu)" e sem vídeo', (tester) async {
      tela(tester);
      await tester.pumpWidget(_app(_Adapter(), copiaDe: original));
      await _settle(tester);
      final nome =
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text;
      expect(nome, 'Supino reto (meu)');
      expect(find.text('Peito'), findsOneWidget); // grupo vindo do original
      expect(
        find.text('Adicionar meu vídeo'),
        findsOneWidget,
      ); // ainda sem vídeo
      expect(find.text('Vídeo escolhido'), findsNothing);
    });

    testWidgets('criar envia o exercício novo sem o vídeo da Focux', (
      tester,
    ) async {
      tela(tester);
      final adapter = _Adapter();
      await tester.pumpWidget(_app(adapter, copiaDe: original));
      await _settle(tester);
      await tester.tap(find.text('Cadastrar'));
      await _settle(tester);
      final post = adapter.chamadas.firstWhere(
        (c) => c.metodo == 'POST' && c.path == '/api/exercicios',
      );
      final corpo = post.corpo as Map;
      expect(corpo['nome'], 'Supino reto (meu)');
      expect(corpo.containsKey('videoUrl'), isFalse);
      expect(adapter.chamadas.where((c) => c.path.endsWith('/video')), isEmpty);
    });
  });

  for (final t in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(t)}', (tester) async {
      usarDynamicTypeMaximo(tester, t);
      await tester.pumpWidget(_app(_Adapter()));
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }

  test('grupo do exercício copiado é o mesmo enum', () {
    expect(GrupoMuscular.peito.backendName, 'PEITO');
  });
}
