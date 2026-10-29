import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Treinos extends TreinoRepository {
  _Treinos(this.fila) : super(ApiClient());

  final RotinaFila fila;

  @override
  Future<FichaVolume> volumeDaFicha(int alunoId) async => FichaVolume.vazio;

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async => fila;
}

class _Modelos extends FichaModeloRepository {
  _Modelos(this.modelos) : super(ApiClient());

  final List<FichaModelo> modelos;
  final salvos = <(String, int)>[];
  final aplicados = <(int, int, bool)>[];

  @override
  Future<List<FichaModelo>> listar() async => modelos;

  @override
  Future<FichaModelo> criarDaFicha({required String nome, required int alunoId}) async {
    salvos.add((nome, alunoId));
    return FichaModelo(id: 99, nome: nome);
  }

  @override
  Future<RotinaFila> aplicar(int id, int alunoId, {bool manterCargas = true}) async {
    aplicados.add((id, alunoId, manterCargas));
    return RotinaFila.vazia;
  }
}

const _fila = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
  ],
);

const _modelos = [
  FichaModelo(
    id: 31,
    nome: 'Hipertrofia 4 dias',
    itens: [
      FichaModeloItem(descanso: false, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
      FichaModeloItem(descanso: false, treinoId: 2, nome: 'Treino B', diaSemana: 2, exerciciosCount: 0),
    ],
  ),
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<_Modelos> _abrir(
  WidgetTester tester, {
  RotinaFila fila = _fila,
  List<FichaModelo> modelos = _modelos,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repoModelos = _Modelos(modelos);
  final router = GoRouter(
    initialLocation: '/alunos/3/rotina',
    routes: [
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (context, state) => const AlunoRotinaScreen(alunoId: 3, alunoNome: ' Ana '),
      ),
      GoRoute(
        path: '/alunos/:id/fichas-anteriores',
        builder: (context, state) =>
            Scaffold(body: Text('fichas anteriores de ${state.extra}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        treinoRepositoryProvider.overrideWithValue(_Treinos(fila)),
        fichaModeloRepositoryProvider.overrideWithValue(repoModelos),
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
  return repoModelos;
}

Future<void> _menuDaFicha(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Opções da ficha'));
  await _settle(tester);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('modelo de ficha (dados)', () {
    test('lê o JSON do backend e resume as sessões', () {
      final modelo = FichaModelo.fromJson({
        'id': 31,
        'nome': 'Hipertrofia 4 dias',
        'avisoDias': [3, 6, 7],
        'itens': [
          {'tipo': 'TREINO', 'treinoId': 1, 'nome': 'Treino A', 'diaSemana': 1, 'exerciciosCount': 5},
          {'tipo': 'TREINO', 'treinoId': 2, 'nome': 'Treino B', 'diaSemana': 2, 'exerciciosCount': 4},
          {'tipo': 'DESCANSO'},
          {'tipo': 'TREINO', 'treinoId': 3, 'nome': 'Peito pesado', 'diaSemana': 4, 'exerciciosCount': 3},
        ],
      });
      expect(modelo.avisoDias, [3, 6, 7]);
      expect(modelo.sessoes, hasLength(3));
      expect(modelo.totalExercicios, 12);
      expect(modelo.pronto, isTrue);
      expect(modelo.resumoDasSessoes, 'A · B · Peito pesado');
    });

    test('com sessão vazia, ainda não está pronto', () {
      expect(_modelos.single.pronto, isFalse);
      expect(_modelos.single.totalExercicios, 5);
      expect(const FichaModelo(id: 1, nome: 'Vazio').pronto, isFalse);
    });
  });

  group('salvar como modelo', () {
    testWidgets('aparece em Pronto quando a ficha tem sessões, e não quando está vazia', (tester) async {
      await _abrir(tester);
      expect(find.text('Salvar como modelo'), findsOneWidget);

      await _abrir(tester, fila: RotinaFila.vazia);
      expect(find.text('Salvar como modelo'), findsNothing);
    });

    testWidgets('pede o nome já sugerido e salva a ficha do aluno', (tester) async {
      final repo = await _abrir(tester);
      await tester.tap(find.text('Salvar como modelo'));
      await _settle(tester);

      expect(find.text('Nome do modelo'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ficha de Ana',
      );
      await tester.enterText(find.byType(TextField), 'Hipertrofia 4 dias');
      await tester.tap(find.text('Pronto').last);
      await _settle(tester);

      expect(repo.salvos, [('Hipertrofia 4 dias', 3)]);
      expect(find.text('Modelo salvo'), findsOneWidget);
    });

    testWidgets('cancelar o nome não salva nada', (tester) async {
      final repo = await _abrir(tester);
      await _menuDaFicha(tester);
      await tester.tap(find.text('Salvar como modelo').last);
      await _settle(tester);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);

      expect(repo.salvos, isEmpty);
    });
  });

  group('aplicar modelo', () {
    testWidgets('sem modelos, avisa em vez de abrir uma lista vazia', (tester) async {
      final repo = await _abrir(tester, modelos: const []);
      await _menuDaFicha(tester);
      await tester.tap(find.text('Aplicar modelo'));
      await _settle(tester);

      expect(find.textContaining('Você ainda não tem modelos'), findsOneWidget);
      expect(repo.aplicados, isEmpty);
    });

    testWidgets('escolhe o modelo, as cargas, confirma a troca e aplica', (tester) async {
      final repo = await _abrir(tester);
      await _menuDaFicha(tester);
      await tester.tap(find.text('Aplicar modelo'));
      await _settle(tester);
      await tester.tap(find.text('Hipertrofia 4 dias'));
      await _settle(tester);
      await tester.tap(find.text('Começar do zero'));
      await _settle(tester);

      expect(find.text('Substituir a ficha?'), findsOneWidget);
      await tester.tap(find.text('Aplicar modelo').last);
      await _settle(tester);

      expect(repo.aplicados, [(31, 3, false)]);
    });

    testWidgets('com a ficha vazia não pergunta se substitui', (tester) async {
      final repo = await _abrir(tester, fila: RotinaFila.vazia);
      await _menuDaFicha(tester);
      await tester.tap(find.text('Aplicar modelo'));
      await _settle(tester);
      await tester.tap(find.text('Hipertrofia 4 dias').last);
      await _settle(tester);
      await tester.tap(find.text('Manter as cargas'));
      await _settle(tester);

      expect(find.text('Substituir a ficha?'), findsNothing);
      expect(repo.aplicados, [(31, 3, true)]);
    });

    testWidgets('na ficha vazia, o modelo aparece na tela e aplica em dois toques', (tester) async {
      final repo = await _abrir(tester, fila: RotinaFila.vazia);

      expect(find.text('Usar um modelo'), findsOneWidget);
      await tester.tap(find.text('Hipertrofia 4 dias'));
      await _settle(tester);
      await tester.tap(find.text('Começar do zero'));
      await _settle(tester);

      expect(find.text('Substituir a ficha?'), findsNothing);
      expect(repo.aplicados, [(31, 3, false)]);
    });

    testWidgets('cancelar a confirmação não aplica', (tester) async {
      final repo = await _abrir(tester);
      await _menuDaFicha(tester);
      await tester.tap(find.text('Aplicar modelo'));
      await _settle(tester);
      await tester.tap(find.text('Hipertrofia 4 dias'));
      await _settle(tester);
      await tester.tap(find.text('Manter as cargas'));
      await _settle(tester);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);

      expect(repo.aplicados, isEmpty);
    });
  });

  group('fichas anteriores no menu da ficha', () {
    testWidgets('o item aparece sempre e abre a lista do aluno', (tester) async {
      await _abrir(tester, fila: RotinaFila.vazia);
      await _menuDaFicha(tester);

      expect(find.text('Fichas anteriores'), findsOneWidget);
      await tester.tap(find.text('Fichas anteriores'));
      await _settle(tester);

      expect(find.text('fichas anteriores de  Ana '), findsOneWidget);
    });
  });
}
