import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final treino = Treino(
    id: 9,
    nome: 'Treino Forca',
    isTemplate: true,
    exercicios: [
      TreinoExercicioItem(
        id: 1,
        exercicio: Exercicio(
          id: 11,
          nome: 'Supino reto',
          grupoMuscularPrimario: GrupoMuscular.peito,
        ),
        series: 3,
        repeticoes: '10-12',
        descansoSegundos: 60,
        ordem: 0,
      ),
    ],
  );

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('detalhe monta com Semantics, freshness e ajuda', (tester) async {
    final router = GoRouter(
      initialLocation: '/treinos/9',
      routes: [
        GoRoute(
          path: '/treinos/:id',
          builder: (context, state) => const TreinoDetailScreen(treinoId: 9),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [treinoProvider.overrideWith((ref, id) async => treino)],
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

    expect(find.bySemanticsLabel('Detalhe do treino'), findsOneWidget);
    expect(find.text('Treino Força'), findsWidgets);
    expect(find.text('Template base'), findsOneWidget);
    expect(find.text('1 exercício · 3 séries · 1 grupo'), findsOneWidget);
    expect(find.text('Atualizado agora'), findsOneWidget);
    expect(find.byTooltip('Como montar este treino'), findsOneWidget);
    expect(find.text('Adicionar exercício'), findsWidgets);
    expect(find.text('Supino reto'), findsOneWidget);
  });
}
