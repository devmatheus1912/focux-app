import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/anamnese/data/anamnese_repository.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/services/recent_exercise_usage_store.dart';
import 'package:focux_app/features/treinos/utils/aluno_restricao_match.dart';
import 'package:focux_app/features/treinos/utils/exercicio_texto.dart';
import 'package:focux_app/features/treinos/utils/exercise_balance.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_sort.dart';
import 'package:focux_app/features/treinos/widgets/add_undo_bar.dart';
import 'package:focux_app/features/treinos/widgets/exercise_alpha_rail.dart';
import 'package:focux_app/features/treinos/widgets/exercise_balance_strip.dart';
import 'package:focux_app/features/treinos/widgets/exercise_group_chips.dart';
import 'package:focux_app/features/treinos/widgets/exercise_library_panel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('texto e ordem', () {
    test('semAcento tira acento e caixa', () {
      expect(semAcento('Tríceps Pulley'), 'triceps pulley');
      expect(semAcento('Abdução'), 'abducao');
      expect(semAcento(null), '');
    });

    test('ordem alfabética estável, sem acento e sem favoritos na frente', () {
      final itens = [
        Exercicio(id: 3, nome: 'Remada', favoritado: true),
        Exercicio(id: 2, nome: 'Água na polia'),
        Exercicio(id: 1, nome: 'Abdominal'),
      ];
      final ordem = sortExerciciosAlfabetico(itens).map((e) => e.nome).toList();
      expect(ordem, ['Abdominal', 'Água na polia', 'Remada']);
    });
  });

  group('equipamento múltiplo', () {
    test('é "ou" entre os equipamentos escolhidos', () {
      final halter = Exercicio(id: 1, nome: 'A', equipamentos: [Equipamento.halter]);
      final polia = Exercicio(id: 2, nome: 'B', equipamentos: [Equipamento.polia]);
      final barra = Exercicio(id: 3, nome: 'C', equipamentos: [Equipamento.barra]);
      final filtro = const ExercisePickerFilter(
        equipamentos: {Equipamento.halter, Equipamento.polia},
      );
      final ok = applyExercisePickerFilter([halter, polia, barra], filtro);
      expect(ok.map((e) => e.id), [1, 2]);
      expect(filtro.isActive, isTrue);
    });
  });

  group('balanço do treino', () {
    test('conta por grupo e ignora nulos', () {
      final b = balancoDoTreino([
        GrupoMuscular.peito,
        GrupoMuscular.peito,
        GrupoMuscular.triceps,
        null,
      ]);
      expect(b, {GrupoMuscular.peito: 2, GrupoMuscular.triceps: 1});
    });

    test('avisa antagonista só com 4+ de um lado e 0 do outro', () {
      expect(
        avisoAntagonista({GrupoMuscular.peito: 4}),
        'Sem costas ainda',
      );
      expect(avisoAntagonista({GrupoMuscular.peito: 3}), isNull);
      expect(
        avisoAntagonista({
          GrupoMuscular.peito: 4,
          GrupoMuscular.costasLatissimo: 1,
        }),
        isNull,
      );
      expect(
        avisoAntagonista({GrupoMuscular.quadriceps: 5}),
        contains('posterior de coxa'),
      );
    });

    test('ordem dos chips: grupos do treino primeiro, depois os maiores', () {
      final ordem = ordemDosGrupos(
        naBiblioteca: {
          GrupoMuscular.peito: 41,
          GrupoMuscular.costasLatissimo: 54,
          GrupoMuscular.triceps: 19,
        },
        noTreino: {GrupoMuscular.triceps: 2},
      );
      expect(ordem.first, GrupoMuscular.triceps);
      expect(ordem[1], GrupoMuscular.costasLatissimo);
      // O número é só o que já está no treino; o da biblioteca não aparece.
      expect(rotuloChipGrupo(nome: 'Peito', noTreino: 0), 'Peito');
      expect(rotuloChipGrupo(nome: 'Tríceps', noTreino: 2), 'Tríceps · 2');
    });

    test('grupos da sessão vêm primeiro na fileira', () {
      final ordem = ordemDosGrupos(
        naBiblioteca: {
          GrupoMuscular.peito: 41,
          GrupoMuscular.costasLatissimo: 54,
          GrupoMuscular.triceps: 19,
        },
        noTreino: {GrupoMuscular.costasLatissimo: 3},
        marcados: {GrupoMuscular.peito, GrupoMuscular.triceps},
      );
      expect(ordem.take(2).toSet(), {GrupoMuscular.peito, GrupoMuscular.triceps});
      expect(ordem[2], GrupoMuscular.costasLatissimo);
    });
  });

  group('restrição do aluno (só aviso)', () {
    test('acha a região por palavra, sem acento nem caixa', () {
      expect(regioesCitadas('Dor no JOELHO direito e coluna'), {
        RegiaoCorpo.joelho,
        RegiaoCorpo.lombar,
      });
      expect(regioesCitadas('Cirurgia no ombro'), {RegiaoCorpo.ombro});
      expect(regioesCitadas(null), isEmpty);
    });

    test('só as contraindicações marcam o exercício', () {
      final aluno = {RegiaoCorpo.joelho};
      final comContra = Exercicio(
        id: 1,
        nome: 'Agachamento',
        contraindicacoes: 'Lesão no joelho ou menisco',
      );
      final soErro = Exercicio(
        id: 2,
        nome: 'Leg press',
        errosComuns: 'Deixar o joelho cair para dentro',
      );
      expect(regioesEmComum(aluno, comContra), {RegiaoCorpo.joelho});
      expect(regioesEmComum(aluno, soErro), isEmpty);
      expect(resumoRegioes({RegiaoCorpo.joelho, RegiaoCorpo.lombar}), 'joelho · lombar');
    });

    test('só há restrição com lesão, dor ou PAR-Q positivo', () {
      expect(anamneseTemRestricao(null), isFalse);
      expect(
        anamneseTemRestricao(
          Anamnese.fromJson({'status': 'PREENCHIDA', 'lesoes': 'Joelho'}),
        ),
        isTrue,
      );
      expect(
        anamneseTemRestricao(Anamnese.fromJson({'status': 'PREENCHIDA'})),
        isFalse,
      );
    });
  });

  group('uso local', () {
    test('recentes por ordem e mais usados por contagem', () async {
      await RecentExerciseUsageStore.recordUsage(1);
      await RecentExerciseUsageStore.recordUsage(2);
      await RecentExerciseUsageStore.recordUsage(2);
      await RecentExerciseUsageStore.recordUsage(3);
      expect(await RecentExerciseUsageStore.recentesIds(), [3, 2, 1]);
      expect((await RecentExerciseUsageStore.maisUsadosIds()).first, 2);
    });
  });

  group('widgets', () {
    testWidgets('AddUndoBar: Desfazer chama e expira sozinha', (tester) async {
      var desfez = 0;
      var expirou = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddUndoBar(
              nome: 'Supino',
              duracao: const Duration(seconds: 2),
              onDesfazer: () => desfez++,
              onExpirar: () => expirou++,
            ),
          ),
        ),
      );
      expect(find.text('Adicionado · Supino'), findsOneWidget);
      await tester.tap(find.text('Desfazer'));
      expect(desfez, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(expirou, 0, reason: 'desfazer cancela o tempo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddUndoBar(
              key: const ValueKey('b'),
              nome: 'Remada',
              duracao: const Duration(seconds: 2),
              onDesfazer: () {},
              onExpirar: () => expirou++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(expirou, 1);
    });

    testWidgets('ExerciseBalanceStrip só mostra o aviso e dispensa', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseBalanceStrip(
              balanco: const {GrupoMuscular.peito: 4},
              primary: Colors.teal,
              isDark: true,
            ),
          ),
        ),
      );
      await tester.pump();
      // "No treino" agora está nos chips de grupo; a faixa é só o aviso.
      expect(find.text('No treino:'), findsNothing);
      expect(find.text('Peito 4'), findsNothing);
      expect(find.text('Sem costas ainda'), findsOneWidget);
      await tester.tap(find.byTooltip('Dispensar aviso'));
      await tester.pump();
      expect(find.text('Sem costas ainda'), findsNothing);
    });

    testWidgets('ExerciseAlphaRail salta para a letra tocada', (tester) async {
      String? letra;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ExerciseAlphaRail(
                letras: const ['A', 'B', 'C', 'D', 'E'],
                isDark: true,
                primary: Colors.teal,
                onLetra: (l) => letra = l,
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(tester.getTopLeft(find.text('A')) + const Offset(2, 2));
      expect(letra, 'A');
      final rail = tester.getRect(find.byType(ExerciseAlphaRail));
      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 4));
      expect(letra, 'E');
    });
  });

  group('painel da biblioteca', () {
    Override pagina(List<Exercicio> itens) =>
        exercicioPickerPageProvider.overrideWith(
          (ref, query) async => ExercicioPickerPage(
            content: itens,
            meta: ExercicioPageMeta(
              page: 0,
              size: 30,
              totalElements: itens.length,
              totalPages: 1,
              hasNext: false,
            ),
          ),
        );

    Future<void> abrir(
      WidgetTester tester,
      List<Exercicio> itens, {
      List<int> recentes = const [],
      List<int> maisUsados = const [],
      Map<GrupoMuscular, int> balanco = const {},
      Set<RegiaoCorpo> regioes = const {},
      Set<GrupoMuscular> gruposIniciais = const {},
      void Function(String? nome)? onCadastrar,
    }) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pagina(itens),
            exercicioPickerStatsProvider.overrideWith(
              (ref) async => const ExercicioPickerStats(
                total: 4,
                porGrupo: {'PEITO': 2, 'TRICEPS': 2},
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder:
                    (context, ref, _) => ExerciseLibraryPanel(
                      alreadyInTreinoIds: const {},
                      filter: const ExercisePickerFilter(),
                      onFilterChanged: (_) {},
                      onLoadPage: ({
                        required busca,
                        required page,
                        required filter,
                        padrao,
                        grupo,
                      }) async => ExercicioPickerPage(
                        content: [
                          for (final e in itens)
                            if (grupo == null ||
                                e.grupoMuscularPrimario == grupo)
                              e,
                        ],
                        meta: const ExercicioPageMeta(
                          page: 0,
                          size: 30,
                          totalElements: 4,
                          totalPages: 1,
                          hasNext: false,
                        ),
                      ),
                      onSelect: (_) {},
                      libraryTotalCount: 4,
                      recentIds: recentes,
                      maisUsadosIds: maisUsados,
                      balanco: balanco,
                      regioesAluno: regioes,
                      gruposIniciais: gruposIniciais,
                      onCadastrar: onCadastrar,
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    final itens = [
      Exercicio(
        id: 1,
        nome: 'Supino reto',
        grupoMuscularPrimario: GrupoMuscular.peito,
        favoritado: true,
        contraindicacoes: 'Lesão no ombro',
      ),
      Exercicio(
        id: 2,
        nome: 'Crucifixo',
        grupoMuscularPrimario: GrupoMuscular.peito,
      ),
      Exercicio(
        id: 3,
        nome: 'Tríceps testa',
        grupoMuscularPrimario: GrupoMuscular.triceps,
      ),
      Exercicio(
        id: 4,
        nome: 'Tríceps corda',
        grupoMuscularPrimario: GrupoMuscular.triceps,
      ),
    ];

    testWidgets('Favoritos numa seção própria, Recentes e Mais usados', (
      tester,
    ) async {
      await abrir(tester, itens, recentes: [3], maisUsados: [2, 3]);
      expect(find.text('Favoritos'), findsOneWidget); // só a seção (o chip saiu)
      expect(find.text('Recentes'), findsOneWidget);
      expect(find.text('Mais usados'), findsOneWidget);
      // sem repetição: o favorito não volta na letra S
      expect(find.text('Supino reto'), findsOneWidget);
      // sem a aba Todos/Músculo
      expect(find.text('Músculo'), findsNothing);
    });

    testWidgets('grupos combináveis: Peito + Tríceps juntos', (tester) async {
      await abrir(tester, itens);
      // Tela larga: a fileira inteira cabe e os chips ficam todos tocáveis.
      await tester.binding.setSurfaceSize(const Size(1400, 844));
      await tester.pump();
      Finder chip(String nome) => find.descendant(
        of: find.byType(ExerciseGroupChips),
        matching: find.text(nome),
      );
      await tester.tap(chip('Peito'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Crucifixo'), findsOneWidget);
      expect(find.text('Tríceps testa'), findsNothing);
      await tester.tap(chip('Tríceps'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Crucifixo'), findsOneWidget);
      expect(find.text('Tríceps testa'), findsOneWidget);
      await tester.tap(chip('Limpar'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tríceps corda'), findsOneWidget);
      expect(chip('Limpar'), findsNothing);
    });

    testWidgets('abre com os grupos da sessão marcados e sem "Limpar"', (tester) async {
      await abrir(tester, itens, gruposIniciais: {GrupoMuscular.triceps});
      expect(find.text('Tríceps testa'), findsOneWidget);
      expect(find.text('Crucifixo'), findsNothing);
      expect(find.text('Limpar'), findsNothing);
      expect(find.text('Equipamento'), findsOneWidget);
    });

    testWidgets('lista até o fim oferece "Criar meu exercício"', (tester) async {
      String? pedido = 'nada';
      await abrir(tester, itens, onCadastrar: (nome) => pedido = nome);
      await tester.dragUntilVisible(
        find.text('Criar meu exercício'),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.text('Criar meu exercício'));
      expect(pedido, isNull);
    });

    testWidgets('marca a região do aluno só como aviso', (tester) async {
      await abrir(tester, itens, regioes: {RegiaoCorpo.ombro});
      expect(find.text('Atenção: ombro'), findsOneWidget);
      expect(find.text('Supino reto'), findsOneWidget);
    });

    testWidgets('"no treino" fica só no chip do grupo', (tester) async {
      await abrir(tester, itens, balanco: {GrupoMuscular.peito: 2});
      expect(find.text('No treino:'), findsNothing);
      expect(find.text('Peito · 2'), findsOneWidget);
    });
  });
}
