import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';
import 'package:focux_app/features/treinos/utils/exercise_search_terms.dart';
import 'package:focux_app/features/treinos/widgets/exercise_library_panel.dart';
import 'package:focux_app/features/treinos/widgets/exercise_library_row.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('termos da busca', () {
    test('reconhece grupo e equipamento, sem acento nem caixa', () {
      final t = termosReconhecidos('Peito HALTER supino');
      expect(t.map((e) => e.rotulo), ['Peito', 'Halter']);
      expect(termosReconhecidos('triceps').single.rotulo, 'Tríceps');
      expect(termosReconhecidos('su'), isEmpty);
      expect(termosReconhecidos('supino reto'), isEmpty);
    });

    test('remover tira só a palavra pedida', () {
      expect(removerTermoDaBusca('peito halter supino', 'halter'), 'peito supino');
      expect(removerTermoDaBusca('Peito', 'peito'), '');
      expect(removerTermoDaBusca('supino', 'peito'), 'supino');
    });
  });

  group('painel', () {
    final itens = [
      for (var i = 0; i < 40; i++)
        Exercicio(
          id: i + 1,
          nome: '${String.fromCharCode(65 + (i ~/ 4))}${i % 4} exercicio ${i + 1}',
          grupoMuscularPrimario: GrupoMuscular.peito,
        ),
    ];

    Future<void> abrir(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exercicioPickerStatsProvider.overrideWith(
              (ref) async =>
                  const ExercicioPickerStats(total: 40, porGrupo: {'PEITO': 40}),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseLibraryPanel(
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
                  content: itens,
                  meta: const ExercicioPageMeta(
                    page: 0,
                    size: 40,
                    totalElements: 40,
                    totalPages: 1,
                    hasNext: false,
                  ),
                ),
                onSelect: (_) {},
                libraryTotalCount: 40,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('busca "peito halter" mostra chips removíveis', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byType(TextField), 'peito halter');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Peito  ✕'), findsOneWidget);
      expect(find.text('Halter  ✕'), findsOneWidget);
      await tester.tap(find.text('Halter  ✕'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Halter  ✕'), findsNothing);
      expect(find.text('Peito  ✕'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'peito',
      );
    });

    testWidgets('o foco da busca continua depois de tocar numa linha', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.focusNode!.hasFocus, isTrue);
      await tester.tap(find.byType(ExerciseLibraryRow).first);
      await tester.pump();
      expect(campo.focusNode!.hasFocus, isTrue);
    });

    testWidgets('a letra da seção fica fixa ao rolar a lista', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);
      expect(find.bySemanticsLabel(RegExp(r'^Seção ')), findsNothing);
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel(RegExp(r'^Seção ')), findsOneWidget);
      semantica.dispose();
    });
  });
}
