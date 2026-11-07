import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_hero.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_medidas_aba.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _tela(Widget filho) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: filho),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('salto de peso marca Confira na linha e abre o Histórico marcado', (tester) async {
    tester.view.physicalSize = const Size(390, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _tela(
        EvolucaoMedidasAba(
          medidas: [
            MedidaCorporal(id: 1, data: '2026-10-30', peso: 90),
            MedidaCorporal(id: 2, data: '2026-11-06', peso: 116),
          ],
          vazioSubtitulo: '',
          onAtualizar: () async {},
          onAbrirRegistro: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confira'), findsOneWidget);

    await tester.tap(find.text('Confira'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico'), findsOneWidget);
    // As duas datas do salto vêm marcadas.
    expect(find.text('Confira'), findsNWidgets(3));
  });

  testWidgets('Definir meta no topo é link, sem botão tonal', (tester) async {
    var tocou = false;
    await tester.pumpWidget(
      _tela(EvolucaoHero(aneis: const EvolucaoAneis(), onDefinirMeta: () => tocou = true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Definir meta'));
    expect(tocou, isTrue);
    expect(find.byType(FilledButton), findsNothing);
  });
}
