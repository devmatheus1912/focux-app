import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_choice_strip.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/features/treinos/utils/semana_do_modelo.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/features/treinos/widgets/ficha_modelos_aba.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends FichaModeloRepository {
  _Repo(this.modelos) : super(ApiClient());

  final List<FichaModelo> modelos;
  final criados = <(String, String)>[];

  @override
  Future<List<FichaModelo>> listar() async => modelos;

  @override
  Future<FichaModelo> criarPelaSemana({required String nome, required List<DiaDaSemana> dias}) async {
    criados.add((
      nome,
      [
        for (final d in dias)
          if (d.sessoes.isNotEmpty) d.sessoes.single.nome else if (d.segueSequencia) 'segue' else '-',
      ].join(' '),
    ));
    return FichaModelo(id: 77, nome: nome);
  }
}

const _hipertrofia = FichaModelo(
  id: 31,
  nome: 'Hipertrofia 4 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
    FichaModeloItem(descanso: false, treinoId: 2, nome: 'Treino B', diaSemana: 2, exerciciosCount: 4),
    FichaModeloItem(descanso: true),
    FichaModeloItem(descanso: false, treinoId: 3, nome: 'Treino C', diaSemana: 4, exerciciosCount: 6),
    FichaModeloItem(descanso: false, treinoId: 4, nome: 'Treino D', diaSemana: 5, exerciciosCount: 7),
  ],
  avisoDias: [3, 6, 7],
);

const _emMontagem = FichaModelo(
  id: 32,
  nome: 'Emagrecimento 3 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 5, nome: 'Treino A', diaSemana: 1, exerciciosCount: 2),
    FichaModeloItem(descanso: false, treinoId: 6, nome: 'Treino B', diaSemana: 3, exerciciosCount: 0),
  ],
  avisoDias: [2, 4, 5, 6, 7],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<(_Repo, List<String>)> _abrir(WidgetTester tester, List<FichaModelo> modelos) async {
  await tester.binding.setSurfaceSize(const Size(430, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _Repo(modelos);
  final aberturas = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: FichaModelosAba(
            abas: FxChoiceStrip<int>(
              itens: const [
                FxChoiceItem(value: 0, label: 'Semanas'),
                FxChoiceItem(value: 1, label: 'Sessões'),
              ],
              selecionado: 0,
              onSelecionar: (_) {},
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/modelos/:id',
        builder: (context, state) {
          aberturas.add(state.pathParameters['id']!);
          return const Scaffold(body: Text('tela do modelo'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fichaModeloRepositoryProvider.overrideWithValue(repo),
        sessoesSemUsoProvider.overrideWith((ref) async => 0),
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
    ),
  );
  await _settle(tester);
  return (repo, aberturas);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('semana do modelo', () {
    test('põe cada sessão no seu dia e os outros dias viram descanso', () {
      final semana = semanaDoModelo(_hipertrofia);
      expect(semana, hasLength(7));
      expect(
        [for (final d in semana) d.sessoes.isEmpty ? '-' : d.sessoes.single.nome],
        ['Treino A', 'Treino B', '-', 'Treino C', 'Treino D', '-', '-'],
      );
      expect(semana.where((d) => d.descanso).map((d) => d.dia), [3, 6, 7]);
      expect(semana.first.sessoes.single.exerciciosCount, 5);
      expect(semana.first.sessoes.single.treinoId, 1);
    });

    test('item sem dia válido fica de fora', () {
      final semana = semanaDoModelo(
        const FichaModelo(
          id: 1,
          nome: 'x',
          itens: [
            FichaModeloItem(descanso: false, treinoId: 1, nome: 'A', diaSemana: 9),
            FichaModeloItem(descanso: false, treinoId: 2, nome: 'B'),
          ],
        ),
      );
      expect(semana.every((d) => d.sessoes.isEmpty), isTrue);
    });
  });

  test('o extra de rota guarda e devolve o modelo', () {
    final extra = const TreinoRouteExtra(modeloId: 31).toExtra();
    expect(extra, {'modeloId': 31});
    expect(TreinoRouteExtra.parse(extra).modeloId, 31);
    expect(TreinoRouteExtra.parse({'modeloId': '8'}).modeloId, 8);
    expect(const TreinoRouteExtra().toExtra(), isNull);
  });

  test('a lista de treinos tem as abas Semanas e Sessões só para a biblioteca', () {
    final lista = File('lib/features/treinos/screens/treinos_list_screen_state.part.dart')
        .readAsStringSync();
    expect(lista, contains('FichaModelosAba'));
    expect(lista, contains('FxChoiceStrip<int>'));
    expect(lista, contains('!fromAluno && _aba == 0'));
  });

  group('aba Semanas', () {
    testWidgets('um card por modelo com letras, contagens e estado', (tester) async {
      await _abrir(tester, const [_hipertrofia, _emMontagem]);

      expect(find.text('Hipertrofia 4 dias'), findsOneWidget);
      expect(find.text('A · B · C · D · 22 exercícios'), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget);
      expect(find.text('Emagrecimento 3 dias'), findsOneWidget);
      expect(find.text('A · B · 2 exercícios'), findsOneWidget);
      expect(find.text('Em montagem'), findsOneWidget);
    });

    testWidgets('tocar no card abre a tela do modelo', (tester) async {
      final (_, aberturas) = await _abrir(tester, const [_hipertrofia]);
      await tester.tap(find.text('Hipertrofia 4 dias'));
      await _settle(tester);

      expect(aberturas, ['31']);
      expect(find.text('tela do modelo'), findsOneWidget);
    });

    testWidgets('sem modelos mostra o convite em vez de uma lista vazia', (tester) async {
      await _abrir(tester, const []);
      expect(find.text('Nenhum modelo ainda'), findsOneWidget);
      expect(find.text('Novo modelo'), findsOneWidget);
    });

    testWidgets('novo modelo: dias e divisão, sem pedir nome, e abre a tela do modelo', (tester) async {
      final (repo, aberturas) = await _abrir(tester, const []);
      await tester.tap(find.text('Novo modelo'));
      await _settle(tester);

      expect(find.text('Quantos dias por semana?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Vale por'), findsNothing);
      await tester.tap(find.text('5'));
      await _settle(tester);
      await tester.tap(find.text('Criar modelo'));
      await _settle(tester);

      expect(repo.criados, [
        ('ABC · 5 dias', 'A · Peito e tríceps B · Costas e bíceps C · Pernas e glúteo segue segue - -'),
      ]);
      expect(aberturas, ['77']);
    });

    testWidgets('cancelar os dias não cria nada', (tester) async {
      final (repo, _) = await _abrir(tester, const []);
      await tester.tap(find.text('Novo modelo'));
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(repo.criados, isEmpty);
    });
  });
}
