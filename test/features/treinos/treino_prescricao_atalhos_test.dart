import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/utils/video_oficial.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/features/treinos/utils/prescricao_atalhos.dart';
import 'package:focux_app/features/treinos/widgets/treino_prescription_video_block.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
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
      jsonEncode({'id': 9, 'nome': 'Treino A', 'exercicios': <dynamic>[]}),
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
      exercicio: Exercicio.fromJson({'id': id + 100, 'nome': 'Exercício $id'}),
      series: 2,
      repeticoes: '10',
      ordem: ordem,
      bloco: bloco,
      descansoSegundos: 30,
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _app(Widget Function() home, {Treino? treino, _Adapter? adapter}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter ?? _Adapter();
  final router = GoRouter(
    initialLocation: '/x',
    routes: [GoRoute(path: '/x', builder: (_, _) => home())],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
      if (treino != null)
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

  group('atalhos', () {
    test('cada bloco tem os seus', () {
      expect(atalhosRepeticoes('TRABALHO'), ['6-8', '8-12', '12-15', '15-20']);
      expect(atalhosRepeticoes('AQUECIMENTO'), ['10', '12', '15', '20']);
      expect(atalhosRepeticoes('ALONGAMENTO'), ['20s', '30s', '45s', '60s']);
      expect(atalhosDescansoSeg('TRABALHO'), [30, 60, 90, 120]);
      expect(atalhosDescansoSeg('ALONGAMENTO'), [0, 10, 15, 30]);
    });

    test('"Outro" marca quando o valor não é atalho', () {
      expect(repeticoesEhAtalho('TRABALHO', '8-12'), isTrue);
      expect(repeticoesEhAtalho('TRABALHO', ' 8-12 '), isTrue);
      expect(repeticoesEhAtalho('TRABALHO', '5'), isFalse);
      expect(descansoEhAtalho('TRABALHO', 75), isFalse);
      expect(descansoEhAtalho('TRABALHO', 90), isTrue);
    });

    test('Mais detalhes abre sozinho se algo já tem valor', () {
      expect(
        maisDetalhesPreenchidos(
          carga: '',
          rpe: '',
          observacoes: '',
          tipoSerie: 'NORMAL',
        ),
        isFalse,
      );
      expect(
        maisDetalhesPreenchidos(
          carga: '20',
          rpe: '',
          observacoes: '',
          tipoSerie: 'NORMAL',
        ),
        isTrue,
      );
      expect(
        maisDetalhesPreenchidos(
          carga: '',
          rpe: '8',
          observacoes: '',
          tipoSerie: 'NORMAL',
        ),
        isTrue,
      );
      expect(
        maisDetalhesPreenchidos(
          carga: '',
          rpe: '',
          observacoes: ' ',
          tipoSerie: 'NORMAL',
        ),
        isFalse,
      );
      expect(
        maisDetalhesPreenchidos(
          carga: '',
          rpe: '',
          observacoes: '',
          tipoSerie: 'superset',
        ),
        isTrue,
      );
    });

  });

  group('vídeo da Focux é fixo', () {
    test('editável só para exercício do personal', () {
      expect(
        videoEditavel(Exercicio.fromJson({'id': 1, 'nome': 'Meu'})),
        isTrue,
      );
      expect(
        videoEditavel(
          Exercicio.fromJson({
            'id': 2,
            'nome': 'Focux',
            'videoSource': 'FOCUX_LIBRARY',
          }),
        ),
        isFalse,
      );
      expect(
        videoEditavel(
          Exercicio.fromJson({'id': 3, 'nome': 'Curado', 'curado': true}),
        ),
        isFalse,
      );
      // cópia da Focux com vídeo próprio: continua do personal
      expect(
        videoEditavel(
          Exercicio.fromJson({
            'id': 4,
            'nome': 'Curado com meu vídeo',
            'curado': true,
            'videoSource': 'PERSONAL_UPLOAD',
          }),
        ),
        isTrue,
      );
    });

    test('nome da cópia leva (meu) uma vez só', () {
      expect(nomeDaCopia('Supino reto'), 'Supino reto (meu)');
      expect(nomeDaCopia('Supino reto (meu)'), 'Supino reto (meu)');
    });

    testWidgets(
      'exercício Focux: sem enviar vídeo, com "Criar meu exercício"',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            () => Scaffold(
              body: TreinoPrescriptionVideoBlock(
                treinoId: 9,
                isDark: false,
                busy: false,
                exercicio: Exercicio.fromJson({
                  'id': 2,
                  'nome': 'Supino Focux',
                  'videoSource': 'FOCUX_LIBRARY',
                  'videoUrl': 'https://cdn.test/v.mp4',
                }),
              ),
            ),
          ),
        );
        await _settle(tester);
        expect(find.text('Criar meu exercício com meu vídeo'), findsOneWidget);
        expect(find.textContaining('Enviar'), findsNothing);
        expect(find.textContaining('Remover'), findsNothing);
        expect(
          find.text(
            'O vídeo da Focux é fixo. Para usar o seu, crie o seu exercício.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('exercício do personal: enviar vídeo disponível', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          () => Scaffold(
            body: TreinoPrescriptionVideoBlock(
              treinoId: 9,
              isDark: false,
              busy: false,
              exercicio: Exercicio.fromJson({'id': 1, 'nome': 'Meu exercício'}),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.textContaining('Enviar'), findsOneWidget);
      expect(find.text('Criar meu exercício com meu vídeo'), findsNothing);
    });
  });

  group('folha de prescrição', () {
    final treino = Treino(
      id: 9,
      nome: 'Treino A',
      exercicios: [
        _item(1, 'AQUECIMENTO', 0),
        _item(2, 'AQUECIMENTO', 1),
        _item(3, 'TRABALHO', 2),
      ],
    );

    Future<_Adapter> abrir(WidgetTester tester, int item) async {
      tester.view.physicalSize = const Size(1290, 3200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final adapter = _Adapter();
      await tester.pumpWidget(
        _app(
          () => const TreinoDetailScreen(treinoId: 9),
          treino: treino,
          adapter: adapter,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Exercício $item'));
      await _settle(tester);
      return adapter;
    }

    testWidgets('aquecimento mostra os atalhos de aquecimento', (tester) async {
      await abrir(tester, 1);
      for (final a in ['10', '12', '15', '20']) {
        expect(find.text(a), findsWidgets, reason: a);
      }
      expect(find.text('6-8'), findsNothing);
      expect(find.text('Aplicar a todo o bloco'), findsOneWidget);
    });

    testWidgets(
      'trabalho sozinho no bloco não oferece "Aplicar a todo o bloco"',
      (tester) async {
        await abrir(tester, 3);
        expect(find.text('6-8'), findsWidgets);
        expect(find.text('Aplicar a todo o bloco'), findsNothing);
      },
    );

    testWidgets('salvar não pede confirmação e aplica ao bloco quando ligado', (
      tester,
    ) async {
      final adapter = await abrir(tester, 1);
      await tester.tap(find.text('20').first);
      await tester.pump();
      await tester.tap(find.text('Aplicar a todo o bloco'));
      await tester.pump();
      await tester.tap(find.text('Salvar prescrição'));
      await _settle(tester);

      expect(find.text('Salvar prescrição?'), findsNothing);
      final atualizacoes = adapter.chamadas.where(
        (c) =>
            c.metodo == 'PATCH' &&
            c.path.startsWith('/api/treinos/9/exercicios/') &&
            !c.path.endsWith('/ordem'),
      );
      final ids = atualizacoes.map((c) => c.path.split('/').last).toSet();
      expect(ids, containsAll(['1', '2']));
      final outro = atualizacoes.firstWhere((c) => c.path.endsWith('/2'));
      expect((outro.corpo as Map)['repeticoes'], '20');
      // o exercício de outro bloco não é tocado
      expect(ids.contains('3'), isFalse);
    });

    testWidgets('sem ligar o interruptor, só o exercício aberto muda', (
      tester,
    ) async {
      final adapter = await abrir(tester, 1);
      await tester.tap(find.text('15').first);
      await tester.pump();
      await tester.tap(find.text('Salvar prescrição'));
      await _settle(tester);
      final ids =
          adapter.chamadas
              .where((c) => c.metodo == 'PATCH' && !c.path.endsWith('/ordem'))
              .map((c) => c.path.split('/').last)
              .toSet();
      expect(ids, {'1'});
    });
  });
}
