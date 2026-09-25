import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/screens/add_exercicio_to_treino_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pickerHome = TreinoPickerHomeBundle(
    treino: Treino(
      id: 12,
      nome: 'Treino Emagrecimento',
      exercicios: const [],
    ),
    libraryCount: 187,
    shortcuts: const [],
    uiHints: TreinoPickerUiHints.fallback(librarySize: 187),
  );

  final pickerPage = ExercicioPickerPage(
    content: [
      Exercicio(id: 1, nome: 'Supino reto'),
      Exercicio(id: 2, nome: 'Agachamento livre'),
    ],
    meta: const ExercicioPageMeta(
      page: 0,
      size: 30,
      totalElements: 187,
      totalPages: 7,
      hasNext: true,
    ),
  );

  Override pickerPageOverride() => exercicioPickerPageProvider.overrideWith(
    (ref, query) async => pickerPage,
  );

  Override statsOverride() => exercicioPickerStatsProvider.overrideWith(
    (ref) async => const ExercicioPickerStats(
      total: 187,
      porGrupo: {'PEITO': 10},
    ),
  );

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, {bool reduceMotion = false}) {
    final router = GoRouter(
      initialLocation: '/treinos/12/exercicios/add',
      routes: [
        GoRoute(
          path: '/treinos/:id/exercicios/add',
          builder:
              (context, state) =>
                  const AddExercicioToTreinoScreen(treinoId: 12),
        ),
      ],
    );

    Widget app = ProviderScope(
      overrides: [
        treinoPickerHomeProvider(12).overrideWith((ref) async => pickerHome),
        pickerPageOverride(),
        statsOverride(),
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
    );

    if (reduceMotion) {
      app = MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app,
      );
    }

    return tester.pumpWidget(app);
  }

  testWidgets('biblioteca é a tela: busca, segmentos e cadastro', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.bySemanticsLabel('Adicionar exercício'), findsOneWidget);
    expect(find.text('Treino Emagrecimento'), findsWidgets);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Movimento'), findsNothing);
    expect(find.text('Músculo'), findsOneWidget);
    expect(find.text('Cadastrar exercício'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Explorar'), findsNothing);
    expect(find.text('Biblioteca completa'), findsNothing);
    expect(find.text('Prescrição'), findsNothing);
    expect(find.textContaining('×'), findsWidgets);
  });

  testWidgets('segmento Músculo mostra grupos sem Explorar', (tester) async {
    await pumpScreen(tester, reduceMotion: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.text('Músculo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Explorar'), findsNothing);
    expect(find.text('Grupos musculares · 1'), findsOneWidget);
    expect(find.text('Peito'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
