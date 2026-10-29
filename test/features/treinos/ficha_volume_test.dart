import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/ficha_volume_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/features/treinos/screens/ficha_modelo_screen.dart';
import 'package:focux_app/features/treinos/utils/ficha_volume_grupos.dart';
import 'package:focux_app/features/treinos/widgets/ficha_volume_secao.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _volume = FichaVolume(
  totalSeries: 26,
  grupos: [
    VolumeGrupo(grupo: 'PEITO', series: 12, exercicios: 3, dias: [1, 4]),
    VolumeGrupo(grupo: 'COSTAS_LATISSIMO', series: 6, exercicios: 2, dias: [2]),
    VolumeGrupo(grupo: 'TRAPEZIO', series: 3, exercicios: 1, dias: [2, 5]),
    VolumeGrupo(grupo: 'OMBRO_LATERAL', series: 3, exercicios: 1, dias: [4]),
  ],
  seriesSemGrupo: 2,
  exerciciosSemGrupo: 1,
);


class _Treinos extends TreinoRepository {
  _Treinos(this.fila) : super(ApiClient());

  final RotinaFila fila;
  var consultasDeVolume = 0;

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async => fila;

  @override
  Future<FichaVolume> volumeDaFicha(int alunoId) async {
    consultasDeVolume++;
    return _volume;
  }
}

class _Modelos extends FichaModeloRepository {
  _Modelos() : super(ApiClient());

  var consultasDeVolume = 0;
  final modelo = const FichaModelo(
    id: 31,
    nome: 'Hipertrofia 4 dias',
    itens: [
      FichaModeloItem(descanso: false, treinoId: 11, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
    ],
  );

  @override
  Future<FichaModelo> buscar(int id) async => modelo;

  @override
  Future<List<FichaModelo>> listar() async => [modelo];

  @override
  Future<FichaVolume> volumeDoModelo(int id) async {
    consultasDeVolume++;
    return _volume;
  }
}

const _fichaComSessao = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('grupos de leitura', () {
    test('os 20 valores do backend caem em algum dos 14 grupos', () {
      const todos = [
        'PEITO', 'COSTAS_LATISSIMO', 'COSTAS_RETANGULARES', 'OMBRO_ANTERIOR', 'OMBRO_LATERAL',
        'OMBRO_POSTERIOR', 'BICEPS', 'TRICEPS', 'ANTEBRACO', 'QUADRICEPS', 'POSTERIOR_COXA',
        'GLUTEO', 'PANTURRILHA', 'ADUTOR', 'ABDUTOR', 'ABDOMEN', 'OBLIQUO', 'LOMBAR', 'TRAPEZIO',
        'FULL_BODY',
      ];
      expect(todos, hasLength(20));
      for (final valor in todos) {
        expect(grupoDeLeitura(valor), isNot(GrupoDeLeitura.outros), reason: valor);
      }
    });

    test('junta como a spec manda', () {
      expect(grupoDeLeitura('COSTAS_LATISSIMO'), GrupoDeLeitura.costas);
      expect(grupoDeLeitura('COSTAS_RETANGULARES'), GrupoDeLeitura.costas);
      expect(grupoDeLeitura('TRAPEZIO'), GrupoDeLeitura.costas);
      expect(grupoDeLeitura('OMBRO_ANTERIOR'), GrupoDeLeitura.ombros);
      expect(grupoDeLeitura('OMBRO_POSTERIOR'), GrupoDeLeitura.ombros);
      expect(grupoDeLeitura('ADUTOR'), GrupoDeLeitura.quadril);
      expect(grupoDeLeitura('ABDUTOR'), GrupoDeLeitura.quadril);
      expect(grupoDeLeitura('OBLIQUO'), GrupoDeLeitura.abdomen);
      expect(grupoDeLeitura('FULL_BODY'), GrupoDeLeitura.corpoTodo);
    });

    test('valor novo que o app não conhece vira Outros, para a conta fechar', () {
      expect(grupoDeLeitura('GRUPO_NOVO'), GrupoDeLeitura.outros);
      final linhas = linhasDeVolume(
        const FichaVolume(totalSeries: 5, grupos: [VolumeGrupo(grupo: 'GRUPO_NOVO', series: 5)]),
      );
      expect(linhas.single.grupo, GrupoDeLeitura.outros);
      expect(linhas.single.series, 5);
    });

    test('soma os valores crus do mesmo grupo e ordena do maior para o menor', () {
      final linhas = linhasDeVolume(_volume);

      expect(linhas.map((l) => l.grupo), [GrupoDeLeitura.peito, GrupoDeLeitura.costas, GrupoDeLeitura.ombros]);
      expect(linhas.map((l) => l.series), [12, 9, 3]);
      expect(linhas[1].exercicios, 3);
    });

    test('junta e ordena os dias de cada grupo, sem repetir', () {
      final costas = linhasDeVolume(_volume).firstWhere((l) => l.grupo == GrupoDeLeitura.costas);
      expect(costas.dias, [2, 5]);
    });

    test('empate de séries desempata pela ordem dos grupos', () {
      final linhas = linhasDeVolume(
        const FichaVolume(
          totalSeries: 12,
          grupos: [
            VolumeGrupo(grupo: 'TRICEPS', series: 6),
            VolumeGrupo(grupo: 'BICEPS', series: 6),
          ],
        ),
      );
      expect(linhas.map((l) => l.grupo), [GrupoDeLeitura.biceps, GrupoDeLeitura.triceps]);
    });

    test('a escala cabe o maior grupo e a faixa de referência inteira', () {
      LinhaDeVolume linha(int s) => LinhaDeVolume(grupo: GrupoDeLeitura.peito, series: s, exercicios: 1, dias: const []);
      expect(escalaDaBarra([linha(12)]), faixaReferenciaMax);
      expect(escalaDaBarra([linha(31), linha(4)]), 31);
      expect(escalaDaBarra(const []), faixaReferenciaMax);
    });

    test('proporção da barra fica entre 0 e 1', () {
      expect(proporcaoDaBarra(10, 20), 0.5);
      expect(proporcaoDaBarra(40, 20), 1);
      expect(proporcaoDaBarra(0, 20), 0);
      expect(proporcaoDaBarra(5, 0), 0);
    });
  });

  group('JSON do volume', () {
    test('lê o contrato do backend', () {
      final volume = FichaVolume.fromJson({
        'totalSeries': 10,
        'grupos': [
          {'grupo': 'PEITO', 'series': 7, 'exercicios': 2, 'dias': [1, 4]},
        ],
        'seriesSemGrupo': 3,
        'exerciciosSemGrupo': 1,
      });
      expect(volume.totalSeries, 10);
      expect(volume.grupos.single.dias, [1, 4]);
      expect(volume.seriesSemGrupo, 3);
      expect(volume.semSeries, isFalse);
    });

    test('resposta vazia ou estranha vira volume zerado', () {
      expect(FichaVolume.fromJson(null).semSeries, isTrue);
      expect(FichaVolume.fromJson('x').semSeries, isTrue);
      expect(FichaVolume.fromJson({}).grupos, isEmpty);
    });
  });

  group('seção Volume da semana', () {
    /// Com [logs], captura as linhas de analytics; quem passa a lista restaura o
    /// debugPrint no fim do teste (restaurar depois quebra a checagem do Flutter).
    Future<void> abrir(
      WidgetTester tester,
      FichaVolume volume, {
      String origem = 'ficha',
      List<String>? logs,
    }) async {
      if (logs != null) {
        debugPrint = (String? mensagem, {int? wrapWidth}) {
          if (mensagem != null && mensagem.contains('ficha_volume_aberto')) logs.add(mensagem);
        };
      }
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fichaVolumeProvider(3).overrideWith((ref) async => volume)],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
              useMaterial3: true,
            ),
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Scaffold(
              body: SingleChildScrollView(
                child: FichaVolumeSecao(provider: fichaVolumeProvider(3), origem: origem),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('começa recolhida, com o título e o total', (tester) async {
      await abrir(tester, _volume);

      expect(find.text('Volume da semana'), findsOneWidget);
      expect(find.text('26 séries de trabalho'), findsOneWidget);
      expect(find.text('Peito'), findsNothing);
      expect(find.textContaining('Referência comum'), findsNothing);
    });

    testWidgets('com rodízio, o total diz que é a 1ª semana', (tester) async {
      await abrir(tester, const FichaVolume(totalSeries: 19, rodizio: true));
      expect(find.text('19 séries de trabalho na 1ª semana'), findsOneWidget);
    });

    test('lê o rodízio do servidor', () {
      expect(FichaVolume.fromJson({'totalSeries': 3, 'rodizio': true}).rodizio, isTrue);
      expect(FichaVolume.fromJson({'totalSeries': 3}).rodizio, isFalse);
    });

    testWidgets('tocar abre os grupos em ordem, a referência e o "sem grupo"', (tester) async {
      await abrir(tester, _volume);
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);

      final ordem = ['Peito', 'Costas', 'Ombros'];
      final posicoes = [for (final nome in ordem) tester.getTopLeft(find.text(nome)).dy];
      expect(posicoes, [...posicoes]..sort());
      expect(find.text('12'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Seg · Qui'), findsOneWidget);
      expect(find.text('Ter · Sex'), findsOneWidget);
      expect(
        find.text('Referência comum para hipertrofia: 10 a 20 séries por semana por grupo. Ajuste ao seu aluno.'),
        findsOneWidget,
      );
      expect(find.text('Sem grupo definido: 2 séries'), findsOneWidget);
    });

    testWidgets('tocar de novo recolhe', (tester) async {
      await abrir(tester, _volume);
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);

      expect(find.text('Peito'), findsNothing);
    });

    testWidgets('a barra é proporcional à escala e a faixa fica entre 10 e 20', (tester) async {
      await abrir(tester, _volume);
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);

      final barras = tester.widgetList<Positioned>(find.byKey(const ValueKey('barra-de-series'))).toList();
      final trilho = tester.getSize(find.byType(LayoutBuilder).first);
      expect(barras, hasLength(3));
      // Escala 20: peito 12 = 60%, costas 9 = 45%, ombros 3 = 15%.
      expect(barras[0].width! / trilho.width, closeTo(0.6, 0.02));
      expect(barras[1].width! / trilho.width, closeTo(0.45, 0.02));
      expect(barras[2].width! / trilho.width, closeTo(0.15, 0.02));
      final faixa = tester.widget<Positioned>(find.byKey(const ValueKey('faixa-referencia')).first);
      expect(faixa.left! / trilho.width, closeTo(0.5, 0.02));
      expect(faixa.width! / trilho.width, closeTo(0.5, 0.02));
    });

    testWidgets('sem séries mostra o convite e não abre', (tester) async {
      await abrir(tester, FichaVolume.vazio);

      expect(find.text('Monte as sessões para ver o volume.'), findsOneWidget);
      await tester.tap(find.text('Volume da semana'), warnIfMissed: false);
      await _settle(tester);
      expect(find.textContaining('Referência comum'), findsNothing);
    });

    testWidgets('sem exercício sem grupo, não mostra a linha final', (tester) async {
      await abrir(
        tester,
        const FichaVolume(totalSeries: 4, grupos: [VolumeGrupo(grupo: 'PEITO', series: 4, exercicios: 1, dias: [1])]),
      );
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);

      expect(find.textContaining('Sem grupo definido'), findsNothing);
    });

    testWidgets('registra a abertura com a origem, e só ao abrir', (tester) async {
      final original = debugPrint;
      final logs = <String>[];
      await abrir(tester, _volume, origem: 'modelo', logs: logs);
      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);
      final aposAbrir = [...logs];

      await tester.tap(find.text('Volume da semana'));
      await _settle(tester);
      final aposFechar = [...logs];
      debugPrint = original;

      expect(aposAbrir, hasLength(1));
      expect(aposAbrir.single, contains('origem: modelo'));
      expect(aposFechar, hasLength(1));
    });

    testWidgets('em erro ou carregando, a seção não aparece', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fichaVolumeProvider(3).overrideWith((ref) => Future<FichaVolume>.error('falhou'))],
          child: MaterialApp(
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Scaffold(body: FichaVolumeSecao(provider: fichaVolumeProvider(3), origem: 'ficha')),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('Volume da semana'), findsNothing);
    });
  });

  group('nas telas', () {
    Future<(GoRouter, _Treinos, _Modelos)> telas(
      WidgetTester tester,
      String inicial,
      RotinaFila fila,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final treinos = _Treinos(fila);
      final modelos = _Modelos();
      final router = GoRouter(
        initialLocation: inicial,
        routes: [
          GoRoute(
            path: '/alunos/:id/rotina',
            builder: (context, state) => const AlunoRotinaScreen(alunoId: 3, alunoNome: 'Ana'),
          ),
          GoRoute(
            path: '/modelos/:id',
            builder: (context, state) => const FichaModeloScreen(modeloId: 31),
          ),
          GoRoute(
            path: '/treinos/:id',
            builder: (context, state) => Scaffold(appBar: AppBar(), body: const Text('montador')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treinoRepositoryProvider.overrideWithValue(treinos),
            fichaModeloRepositoryProvider.overrideWithValue(modelos),
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
      return (router, treinos, modelos);
    }

    testWidgets('a ficha com sessões mostra o volume da semana', (tester) async {
      await telas(tester, '/alunos/3/rotina', _fichaComSessao);
      expect(find.text('Volume da semana'), findsOneWidget);
      expect(find.text('26 séries de trabalho'), findsOneWidget);
    });

    testWidgets('a ficha vazia não mostra o volume e nem consulta', (tester) async {
      final (_, treinos, _) = await telas(tester, '/alunos/3/rotina', RotinaFila.vazia);
      expect(find.text('Volume da semana'), findsNothing);
      expect(treinos.consultasDeVolume, 0);
    });

    testWidgets('voltar do montador consulta o volume de novo', (tester) async {
      final (router, treinos, _) = await telas(tester, '/alunos/3/rotina', _fichaComSessao);
      final antes = treinos.consultasDeVolume;
      expect(antes, greaterThanOrEqualTo(1));

      await tester.tap(find.text('Peito'));
      await _settle(tester);
      router.pop();
      await _settle(tester);

      expect(treinos.consultasDeVolume, greaterThan(antes));
    });

    testWidgets('a tela do modelo mostra o mesmo resumo', (tester) async {
      await telas(tester, '/modelos/31', _fichaComSessao);
      expect(find.text('Volume da semana'), findsOneWidget);
      expect(find.text('26 séries de trabalho'), findsOneWidget);
    });

    testWidgets('voltar do montador do modelo consulta o volume de novo', (tester) async {
      final (router, _, modelos) = await telas(tester, '/modelos/31', _fichaComSessao);
      final antes = modelos.consultasDeVolume;

      await tester.tap(find.text('Treino A'));
      await _settle(tester);
      router.pop();
      await _settle(tester);

      expect(modelos.consultasDeVolume, greaterThan(antes));
    });
  });
}
