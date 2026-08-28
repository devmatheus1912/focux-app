import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/add_exercicio_to_treino_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    uiHints: TreinoPickerUiHints.fallback(librarySize: 187, jaNoTreino: 0),
  );

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('aba Buscar mostra contagem real da biblioteca e a11y', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/treinos/12/exercicios/add',
      routes: [
        GoRoute(
          path: '/treinos/:id/exercicios/add',
          builder:
              (context, state) =>
                  AddExercicioToTreinoScreen(treinoId: 12),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          treinoPickerHomeProvider(12).overrideWith((ref) async => pickerHome),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.bySemanticsLabel('Adicionar exercício'), findsOneWidget);
    expect(find.text('Treino Emagrecimento'), findsWidgets);
    expect(find.text('Biblioteca completa (187)'), findsOneWidget);
    expect(find.textContaining('187 exercícios'), findsWidgets);
    expect(find.text('Cadastrar exercício'), findsOneWidget);
    expect(find.text('0 exercícios'), findsNothing);
  });

  testWidgets('reduce motion desativa slide entre abas', (tester) async {
    final router = GoRouter(
      initialLocation: '/treinos/12/exercicios/add',
      routes: [
        GoRoute(
          path: '/treinos/:id/exercicios/add',
          builder:
              (context, state) =>
                  AddExercicioToTreinoScreen(treinoId: 12),
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ProviderScope(
          overrides: [
            treinoPickerHomeProvider(12).overrideWith((ref) async => pickerHome),
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.text('Explorar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Explorar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
