import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/screens/ficha_modelo_screen.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends FichaModeloRepository {
  _Repo(this.modelo) : super(ApiClient());

  FichaModelo modelo;
  final renomeados = <String>[];
  final arquivados = <int>[];
  final aplicados = <(int, int, bool)>[];

  @override
  Future<FichaModelo> buscar(int id) async => modelo;

  @override
  Future<List<FichaModelo>> listar() async => [modelo];

  @override
  Future<FichaModelo> renomear(int id, String nome) async {
    renomeados.add(nome);
    modelo = FichaModelo(id: modelo.id, nome: nome, itens: modelo.itens);
    return modelo;
  }

  @override
  Future<void> arquivar(int id) async => arquivados.add(id);

  @override
  Future<RotinaFila> aplicar(int id, int alunoId, {bool manterCargas = true}) async {
    aplicados.add((id, alunoId, manterCargas));
    return RotinaFila.vazia;
  }
}

const _modelo = FichaModelo(
  id: 31,
  nome: 'Hipertrofia 4 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 11, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
    FichaModeloItem(descanso: false, treinoId: 12, nome: 'Treino B', diaSemana: 2, exerciciosCount: 0),
    FichaModeloItem(descanso: true),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<(_Repo, List<Object?>)> _abrir(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _Repo(_modelo);
  final aberturas = <Object?>[];
  final router = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(path: '/inicio', builder: (context, state) => const Scaffold(body: Text('inicio'))),
      GoRoute(path: '/modelos/:id', builder: (context, state) => const FichaModeloScreen(modeloId: 31)),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) {
          aberturas.add((state.pathParameters['id'], state.extra));
          return Scaffold(appBar: AppBar(), body: const Text('montador'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fichaModeloRepositoryProvider.overrideWithValue(repo),
        alunosProvider.overrideWith(
          (ref) async => [
            Aluno(id: 3, nome: 'Ana Souza', email: 'a@a.com', status: 'ATIVO'),
            Aluno(id: 4, nome: 'Bia Lima', email: 'b@b.com', status: 'ATIVO'),
          ],
        ),
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
  router.push('/modelos/31');
  await _settle(tester);
  return (repo, aberturas);
}

Future<void> _menu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Opções da ficha'));
  await _settle(tester);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('tela do modelo cumpre o contrato das telas', () {
    final fonte = File('lib/features/treinos/screens/ficha_modelo_screen.dart').readAsStringSync();
    expect(fonte, contains('fxScreenA11yScope'));
    expect(fonte, contains('FxLoading'));
    expect(fonte, isNot(contains('CircularProgressIndicator')));
    expect(fonte, contains('FxStickyActions'));
    expect(fonte, contains('FichaSemana'));
    for (final fixo in ["'Aplicar em aluno'", "'Renomear'", "'Excluir modelo'", "'Cancelar'"]) {
      expect(fonte, isNot(contains(fixo)));
    }
  });

  testWidgets('mostra o nome, as contagens e a semana do modelo', (tester) async {
    await _abrir(tester);

    expect(find.text('Hipertrofia 4 dias'), findsWidgets);
    expect(find.text('2 sessões · 5 exercícios · Em montagem'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('Treino B'), findsOneWidget);
    expect(find.text('5 exercícios'), findsOneWidget);
    expect(find.text('Montar'), findsOneWidget);
    expect(find.text('Aplicar em aluno'), findsOneWidget);
    expect(find.byType(FxLiquidPrimaryButton), findsOneWidget);
  });

  testWidgets('a semana do modelo é só de leitura: sem "…" por sessão', (tester) async {
    await _abrir(tester);
    expect(find.byTooltip('Mais ações da sessão'), findsNothing);
    expect(find.text('Adicionar treino'), findsNothing);
  });

  testWidgets('tocar numa sessão abre o montador com o modelo no extra', (tester) async {
    final (_, aberturas) = await _abrir(tester);

    await tester.tap(find.text('Treino A'));
    await _settle(tester);

    expect(find.text('montador'), findsOneWidget);
    final (id, extra) = aberturas.single! as (String?, Object?);
    expect(id, '11');
    expect(TreinoRouteExtra.parse(extra).modeloId, 31);
    expect(TreinoRouteExtra.parse(extra).alunoId, isNull);
  });

  testWidgets('renomear pede o nome e salva', (tester) async {
    final (repo, _) = await _abrir(tester);
    await _menu(tester);
    await tester.tap(find.text('Renomear'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Full body');
    await tester.tap(find.text('Pronto').last);
    await _settle(tester);

    expect(repo.renomeados, ['Full body']);
  });

  testWidgets('excluir pede confirmação, arquiva e volta', (tester) async {
    final (repo, _) = await _abrir(tester);
    await _menu(tester);
    await tester.tap(find.text('Excluir modelo'));
    await _settle(tester);

    expect(find.text('Excluir o modelo?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);
    expect(repo.arquivados, isEmpty);

    await _menu(tester);
    await tester.tap(find.text('Excluir modelo'));
    await _settle(tester);
    await tester.tap(find.text('Excluir modelo').last);
    await _settle(tester);

    expect(repo.arquivados, [31]);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('aplicar em aluno: escolhe o aluno, as cargas, confirma e aplica', (tester) async {
    final (repo, _) = await _abrir(tester);
    await tester.tap(find.text('Aplicar em aluno'));
    await _settle(tester);
    await tester.tap(find.text('Bia Lima'));
    await _settle(tester);
    await tester.tap(find.text('Manter as cargas'));
    await _settle(tester);

    expect(find.text('Substituir a ficha?'), findsOneWidget);
    await tester.tap(find.text('Aplicar em aluno').last);
    await _settle(tester);

    expect(repo.aplicados, [(31, 4, true)]);
    expect(find.text('Ficha aplicada em Bia Lima'), findsOneWidget);
  });

  testWidgets('cancelar a escolha do aluno não aplica nada', (tester) async {
    final (repo, _) = await _abrir(tester);
    await tester.tap(find.text('Aplicar em aluno'));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    expect(repo.aplicados, isEmpty);
  });
}
