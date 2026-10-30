import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/modelos_de_treino_view.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Modelos de treino: só Semanas e Exercícios, e conta modelos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichaModelosProvider.overrideWith(
            (ref) async => const [FichaModelo(id: 1, nome: 'ABC · 3 dias')],
          ),
          sessoesSemUsoProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const ModelosDeTreinoView(),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Semanas'), findsOneWidget);
    expect(find.text('Exercícios'), findsOneWidget);
    expect(find.text('Sessões'), findsNothing);
    expect(find.text('1 modelo'), findsOneWidget);
    expect(find.byTooltip('Selecionar treinos'), findsNothing);
  });
}
