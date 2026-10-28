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
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
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
    final corpo =
        options.method == 'DELETE'
            ? <String, Object>{}
            : {'id': 9, 'nome': 'Treino A', 'exercicios': <dynamic>[]};
    return ResponseBody.fromString(
      jsonEncode(corpo),
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

TreinoExercicioItem _item(int id, String bloco, int ordem) =>
    TreinoExercicioItem(
      id: id,
      exercicio: Exercicio(
        id: id + 100,
        nome: 'Exercício $id',
        grupoMuscularPrimario: GrupoMuscular.peito,
      ),
      series: 3,
      repeticoes: '10',
      ordem: ordem,
      bloco: bloco,
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _app(Treino treino, _Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: '/treinos/9',
    routes: [
      GoRoute(
        path: '/treinos/:id',
        builder: (_, _) => const TreinoDetailScreen(treinoId: 9),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
      treinoProvider.overrideWith((ref, id) async => treino),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  void tela(WidgetTester tester) {
    tester.view.physicalSize = const Size(1290, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  final treino = Treino(
    id: 9,
    nome: 'Treino A',
    exercicios: [
      _item(1, 'AQUECIMENTO', 0),
      _item(2, 'AQUECIMENTO', 1),
      _item(3, 'AQUECIMENTO', 2),
      _item(4, 'TRABALHO', 3),
      _item(5, 'ALONGAMENTO', 4),
      _item(6, 'ALONGAMENTO', 5),
    ],
  );

  testWidgets(
    'três aquecimentos e dois alongamentos, cada seção com + Adicionar',
    (tester) async {
      tela(tester);
      await tester.pumpWidget(_app(treino, _Adapter()));
      await _settle(tester);
      for (final i in [1, 2, 3, 4, 5, 6]) {
        expect(find.text('Exercício $i'), findsOneWidget);
      }
      expect(find.text('Aquecimento · 3'), findsOneWidget);
      expect(find.text('Alongamento e volta à calma · 2'), findsOneWidget);
      expect(find.text('Adicionar'), findsNWidgets(3));
      expect(find.text('Segure para reordenar'), findsNothing);
      // um cabeçalho de grupo muscular dentro do bloco não existe mais
      expect(find.text('PEITO'), findsNothing);
      expect(find.text('6 exercícios · ~30 min · 1 grupo'), findsOneWidget);
    },
  );

  testWidgets('seção vazia mostra o convite', (tester) async {
    tela(tester);
    final soTrabalho = Treino(
      id: 9,
      nome: 'Treino A',
      exercicios: [_item(1, 'TRABALHO', 0)],
    );
    await tester.pumpWidget(_app(soTrabalho, _Adapter()));
    await _settle(tester);
    expect(
      find.text('Nenhum exercício. Toque para adicionar.'),
      findsNWidgets(2),
    );
  });

  testWidgets('arrastar pela alça de Trabalho para o Aquecimento muda o bloco', (
    tester,
  ) async {
    tela(tester);
    final adapter = _Adapter();
    await tester.pumpWidget(_app(treino, adapter));
    await _settle(tester);

    final alcas = find.byIcon(Icons.drag_indicator_rounded);
    // alça do exercício 4 (único de Trabalho): sobe por cima de 3 linhas e do cabeçalho
    final alca4 = alcas.at(3);
    final gesto = await tester.startGesture(tester.getCenter(alca4));
    await tester.pump(const Duration(milliseconds: 100));
    await gesto.moveBy(const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 100));
    await gesto.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 100));
    await gesto.up();
    await _settle(tester);

    final put = adapter.chamadas.where(
      (c) =>
          c.metodo == 'PUT' && c.path == '/api/treinos/9/exercicios/4/series',
    );
    expect(put, hasLength(1));
    expect((put.single.corpo as Map)['bloco'], 'AQUECIMENTO');
    final patch = adapter.chamadas.singleWhere(
      (c) => c.metodo == 'PATCH' && c.path == '/api/treinos/9/exercicios/ordem',
    );
    final ids = ((patch.corpo as Map)['itemIds'] as List).cast<int>();
    expect([...ids]..sort(), [1, 2, 3, 4, 5, 6]);
    expect(ids.indexOf(4), lessThan(3));
  });

  testWidgets('"Mover para…" leva o exercício para outro bloco', (
    tester,
  ) async {
    tela(tester);
    final adapter = _Adapter();
    await tester.pumpWidget(_app(treino, adapter));
    await _settle(tester);

    await tester.tap(find.byTooltip('Ações de Exercício 4'));
    await _settle(tester);
    await tester.tap(find.text('Mover para…'));
    await _settle(tester);
    // o bloco atual (Trabalho) não é oferecido
    expect(find.text('Trabalho'), findsNothing);
    await tester.tap(find.text('Alongamento e volta à calma').last);
    await _settle(tester);

    final put = adapter.chamadas.singleWhere(
      (c) =>
          c.metodo == 'PUT' && c.path == '/api/treinos/9/exercicios/4/series',
    );
    expect((put.corpo as Map)['bloco'], 'ALONGAMENTO');
    expect(
      adapter.chamadas.any(
        (c) => c.metodo == 'PATCH' && c.path.endsWith('/ordem'),
      ),
      isTrue,
    );
  });

  testWidgets('remover é imediato e oferece Desfazer', (tester) async {
    tela(tester);
    final adapter = _Adapter();
    await tester.pumpWidget(_app(treino, adapter));
    await _settle(tester);

    await tester.tap(find.byTooltip('Ações de Exercício 4'));
    await _settle(tester);
    await tester.tap(find.text('Remover do treino'));
    await _settle(tester);
    expect(
      adapter.chamadas.any(
        (c) => c.metodo == 'DELETE' && c.path == '/api/treinos/9/exercicios/4',
      ),
      isTrue,
    );
    expect(find.text('Exercício 4 saiu do treino.'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
  });

  for (final t in kDynamicTypeTelas) {
    testWidgets('aguenta ${descreverTela(t)}', (tester) async {
      usarDynamicTypeMaximo(tester, t);
      await tester.pumpWidget(_app(treino, _Adapter()));
      await _settle(tester);
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex?.toString());
    });
  }
}
