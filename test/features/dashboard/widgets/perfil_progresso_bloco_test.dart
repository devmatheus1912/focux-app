import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_progresso_bloco.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/providers/evolucao_home_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

MedidaCorporal _medida(int id, String data, double peso) => MedidaCorporal.fromJson({
  'id': id,
  'data': data,
  'peso': peso,
});

Future<void> _abrir(WidgetTester tester, List<MedidaCorporal> medidas) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder:
            (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: PerfilProgressoBloco(medidas: medidas),
              ),
            ),
      ),
      GoRoute(
        path: '/aluno/progresso',
        builder: (_, _) => const Scaffold(body: Text('PROGRESSO')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        minhaEvolucaoProvider.overrideWith(
          (ref) async => EvolucaoHomeBundle(medidas: medidas, recordes: const []),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('título é Meu progresso e o peso sai com uma casa', (tester) async {
    await _abrir(tester, [
      _medida(1, '2026-10-30', 90),
      _medida(2, '2026-11-02', 105),
    ]);
    expect(find.text('Meu progresso'), findsOneWidget);
    expect(find.text('Peso: 105,0 kg · +15,0 kg'), findsOneWidget);
    expect(find.text('Peso atual'), findsNothing);
  });

  testWidgets('sem medida, o card abre o progresso', (tester) async {
    await _abrir(tester, const []);
    expect(find.text('Peso: Sem medida'), findsOneWidget);
    await tester.tap(find.text('Peso: Sem medida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PROGRESSO'), findsOneWidget);
  });
}
