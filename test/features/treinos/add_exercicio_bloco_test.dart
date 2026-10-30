import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/data/exercise_prescription_memory_store.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/add_exercicio_to_treino_screen.dart';
import 'package:focux_app/features/treinos/utils/prescricao_padrao_bloco.dart';
import 'package:focux_app/features/treinos/utils/prescricao_serie.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Chamada {
  _Chamada(this.metodo, this.path, this.corpo);

  final String metodo;
  final String path;
  final Object? corpo;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.bloco);

  final String bloco;
  final List<_Chamada> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(_Chamada(options.method, options.path, options.data));
    final corpo = {
      'id': 12,
      'nome': 'Treino A',
      'exercicios': [
        {
          'id': 77,
          'exercicio': {'id': 1, 'nome': 'Supino reto'},
          'series': 2,
          'repeticoes': '15',
          'ordem': 0,
          'bloco': bloco,
        },
      ],
    };
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('padrão por bloco', () {
    test(
      'aquecimento 2 × 15 · 45 s, alongamento 2 × 30 s, trabalho de hipertrofia',
      () {
        expect(
          (
            padraoDoBloco('AQUECIMENTO').series,
            padraoDoBloco('AQUECIMENTO').repeticoes,
            padraoDoBloco('AQUECIMENTO').descansoSegundos,
          ),
          (2, '15', 45),
        );
        expect(
          (
            padraoDoBloco('ALONGAMENTO').series,
            padraoDoBloco('ALONGAMENTO').repeticoes,
          ),
          (2, '30s'),
        );
        expect(padraoDoBloco('TRABALHO').series, prescricaoHipertrofiaSeries);
        expect(padraoDoBloco('AJUSTE').repeticoes, prescricaoHipertrofiaReps);
      },
    );

    test('as linhas do padrão são séries válidas numeradas', () {
      final l = padraoDoBloco('AQUECIMENTO').linhas;
      expect(l.map((s) => s.numero), [1, 2]);
      expect(l.every((s) => !s.aquecimento && s.repeticoes == '15'), isTrue);
    });

    test('só o trabalho usa a memória global', () {
      expect(usaMemoriaGlobal('TRABALHO'), isTrue);
      expect(usaMemoriaGlobal('AQUECIMENTO'), isFalse);
      expect(usaMemoriaGlobal('ALONGAMENTO'), isFalse);
    });

    test('chave de memória: trabalho como sempre, os outros separados', () {
      expect(
        chaveMemoriaDoExercicio(5, 'TRABALHO'),
        'exercise_prescription_v1_5',
      );
      expect(
        chaveMemoriaDoExercicio(5, 'AQUECIMENTO'),
        'exercise_prescription_v1_5_AQUECIMENTO',
      );
    });

    test('destino no título', () {
      expect(destinoDoAdicionar('AQUECIMENTO'), 'Adicionando ao aquecimento');
      expect(destinoDoAdicionar('ALONGAMENTO'), 'Adicionando ao alongamento');
      expect(destinoDoAdicionar('TRABALHO'), 'Adicionando ao treino');
    });
  });

  group('memória por bloco', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'prescrição de aquecimento não vira a do trabalho nem a global',
      () async {
        await ExercisePrescriptionMemoryStore.saveFor(5, const [
          SeriePrescrita(numero: 1, repeticoes: '15'),
        ], bloco: 'AQUECIMENTO');
        expect(
          (await ExercisePrescriptionMemoryStore.loadFor(
            5,
            bloco: 'AQUECIMENTO',
          ))?.length,
          1,
        );
        expect(await ExercisePrescriptionMemoryStore.loadFor(5), isNull);
        expect(
          await ExercisePrescriptionMemoryStore.loadGlobalSeries(),
          isNull,
        );
      },
    );

    test('prescrição do trabalho segue sendo a global', () async {
      await ExercisePrescriptionMemoryStore.saveFor(6, const [
        SeriePrescrita(numero: 1, repeticoes: '6-8'),
        SeriePrescrita(numero: 2, repeticoes: '6-8'),
      ]);
      final global = await ExercisePrescriptionMemoryStore.loadGlobalSeries();
      expect(global?.length, 2);
      expect(global?.first.repeticoes, '6-8');
    });
  });

  group('tela adicionando a um bloco', () {
    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
    });

    Future<_Adapter> abrir(
      WidgetTester tester,
      String bloco, {
      List<TreinoExercicioItem> noTreino = const [],
    }) async {
      tester.view.physicalSize = const Size(1290, 2800);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final adapter = _Adapter(bloco);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final home = TreinoPickerHomeBundle(
        treino: Treino(id: 12, nome: 'Treino A', exercicios: noTreino),
        libraryCount: 2,
        shortcuts: const [],
        uiHints: TreinoPickerUiHints.fallback(librarySize: 2),
      );
      final router = GoRouter(
        initialLocation: '/add',
        routes: [
          GoRoute(
            path: '/add',
            builder:
                (_, _) =>
                    AddExercicioToTreinoScreen(treinoId: 12, bloco: bloco),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
            treinoPickerHomeProvider(12).overrideWith((ref) async => home),
            exercicioPickerPageProvider.overrideWith(
              (ref, query) async => ExercicioPickerPage(
                content: [Exercicio(id: 1, nome: 'Supino reto')],
                meta: const ExercicioPageMeta(
                  page: 0,
                  size: 30,
                  totalElements: 1,
                  totalPages: 1,
                  hasNext: false,
                ),
              ),
            ),
            exercicioPickerStatsProvider.overrideWith(
              (ref) async => const ExercicioPickerStats(total: 2, porGrupo: {}),
            ),
          ],
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
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return adapter;
    }

    testWidgets(
      'aquecimento: título com destino, padrão 2 × 15 e "Pronto · 1 adicionado"',
      (tester) async {
        final adapter = await abrir(tester, 'AQUECIMENTO');
        expect(find.text('Adicionando ao aquecimento'), findsOneWidget);
        expect(find.byTooltip('Fechar'), findsOneWidget);

        await tester.tap(find.text('Supino reto'));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final post = adapter.chamadas.firstWhere(
          (c) => c.metodo == 'POST' && c.path == '/api/treinos/12/exercicios',
        );
        final corpo = post.corpo as Map;
        expect(corpo['bloco'], 'AQUECIMENTO');
        expect(corpo['series'], 2);
        expect(corpo['repeticoes'], '15');
        expect(corpo['descansoSegundos'], 45);
        // Séries iguais: o servidor já cria tudo na mesma chamada.
        expect(
          adapter.chamadas.where(
            (c) => c.metodo == 'PUT' && c.path.endsWith('/series'),
          ),
          isEmpty,
        );
        expect(find.text('Pronto · 1 adicionado'), findsOneWidget);
        expect(find.text('Adicionado · Supino reto'), findsOneWidget);
        expect(find.text('Desfazer'), findsOneWidget);
      },
    );

    testWidgets('trabalho: sem campo bloco na chamada (padrão do servidor)', (
      tester,
    ) async {
      final adapter = await abrir(tester, 'TRABALHO');
      expect(find.text('Adicionando ao treino'), findsOneWidget);
      await tester.tap(find.text('Supino reto'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final post = adapter.chamadas.firstWhere(
        (c) => c.metodo == 'POST' && c.path == '/api/treinos/12/exercicios',
      );
      expect((post.corpo as Map).containsKey('bloco'), isFalse);
      expect((post.corpo as Map)['series'], prescricaoHipertrofiaSeries);
    });

    testWidgets(
      'exercício já no treino: oferece ajustar ou adicionar de novo',
      (tester) async {
        final adapter = await abrir(
          tester,
          'TRABALHO',
          noTreino: [
            TreinoExercicioItem(
              id: 77,
              exercicio: Exercicio(id: 1, nome: 'Supino reto'),
              series: 3,
              repeticoes: '8-12',
              ordem: 0,
            ),
          ],
        );
        // a linha mostra a prescrição aplicada
        expect(find.textContaining('No treino · 3 × 8-12'), findsOneWidget);

        await tester.tap(find.text('Supino reto'));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Já está neste treino'), findsOneWidget);
        expect(find.text('Ajustar prescrição'), findsOneWidget);
        expect(find.text('Adicionar de novo'), findsOneWidget);
        // nada foi adicionado só por tocar
        expect(adapter.chamadas.where((c) => c.metodo == 'POST'), isEmpty);

        await tester.tap(find.text('Adicionar de novo'));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(adapter.chamadas.where((c) => c.metodo == 'POST'), hasLength(1));
      },
    );
  });
}
