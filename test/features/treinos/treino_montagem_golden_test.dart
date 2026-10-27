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
import 'package:focux_app/core/widgets/fx_grouped_action_sheet.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'id': 9, 'nome': 'Treino A', 'exercicios': <dynamic>[]}),
    200,
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

TreinoExercicioItem _item(
  int id,
  String nome,
  String bloco,
  int ordem,
  GrupoMuscular g,
) => TreinoExercicioItem(
  id: id,
  exercicio: Exercicio(id: id + 100, nome: nome, grupoMuscularPrimario: g),
  series: bloco == 'TRABALHO' ? 4 : 2,
  repeticoes: bloco == 'TRABALHO' ? '8-12' : '15',
  ordem: ordem,
  bloco: bloco,
  descansoSegundos: bloco == 'TRABALHO' ? 75 : 45,
);

final _treino = Treino(
  id: 9,
  nome: 'Treino Hipertrofia',
  exercicios: [
    _item(1, 'Mobilidade de quadril', 'AQUECIMENTO', 0, GrupoMuscular.gluteo),
    _item(2, 'Ponte de glúteo', 'AQUECIMENTO', 1, GrupoMuscular.gluteo),
    _item(3, 'Agachamento livre', 'TRABALHO', 2, GrupoMuscular.quadriceps),
    _item(4, 'Cadeira flexora', 'TRABALHO', 3, GrupoMuscular.posteriorCoxa),
    _item(
      5,
      'Alongamento de posterior',
      'ALONGAMENTO',
      4,
      GrupoMuscular.posteriorCoxa,
    ),
  ],
);

Widget _app({required bool dark, double scale = 1.0}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter();
  final router = GoRouter(
    initialLocation: '/t',
    routes: [
      GoRoute(
        path: '/t',
        builder: (_, _) => const TreinoDetailScreen(treinoId: 9),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeApiClient(dio)),
      treinoProvider.overrideWith((ref, id) async => _treino),
    ],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: EagleTokens.brandAccent,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Future<void> abrir(
    WidgetTester tester, {
    required bool dark,
    double scale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(dark: dark, scale: scale));
    await _settle(tester);
  }

  testWidgets('treino com aquecimento, trabalho e alongamento (claro)', (
    tester,
  ) async {
    await abrir(tester, dark: false);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/treino_montagem_390.png',
    );
  });

  testWidgets('treino com aquecimento, trabalho e alongamento (escuro)', (
    tester,
  ) async {
    await abrir(tester, dark: true);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/treino_montagem_390_dark.png',
    );
  });

  testWidgets('treino (fonte 1.3)', (tester) async {
    await abrir(tester, dark: false, scale: 1.3);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/treino_montagem_390_scale13.png',
    );
  });

  testWidgets('folha de ações do treino em grupos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => showFxGroupedActionSheet<String>(
                          context,
                          titulo: 'Ações do treino',
                          subtitulo: 'Treino Hipertrofia',
                          icone: Icons.fitness_center_rounded,
                          grupos: const [
                            FxActionGroup('Montar', [
                              FxActionItem(
                                valor: 'a',
                                rotulo: 'Adicionar exercício',
                                icone: Icons.add_rounded,
                              ),
                              FxActionItem(
                                valor: 'b',
                                rotulo: 'Montar por modelo',
                                icone: Icons.view_agenda_outlined,
                              ),
                            ]),
                            FxActionGroup('Usar', [
                              FxActionItem(
                                valor: 'c',
                                rotulo: 'Atribuir a aluno',
                                descricao:
                                    'Mesmo treino: suas edições chegam ao aluno',
                                icone: Icons.person_add_alt_1_rounded,
                              ),
                            ]),
                          ],
                          destrutiva: const FxActionItem(
                            valor: 'd',
                            rotulo: 'Excluir treino',
                            icone: Icons.delete_outline_rounded,
                          ),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/folha_acoes_agrupada_390.png',
    );
  });
}
