@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_cartao.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_selo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

const _teal = Color(0xFF0E5A66);
const _limao = Color(0xFFD4E157);

Widget _tela(Widget filho, {required bool escuro, required Color marca}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: marca).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: marca).copyWith(primary: marca),
  ),
  darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: marca, brightness: Brightness.dark)
        .copyWith(primary: marca),
  ),
  themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: Center(child: filho)),
);

Conquista _conquista(ConquistaTipo tipo) => Conquista(
  chave: 'x',
  tipo: tipo,
  titulo: '−8,0 kg',
  detalhe: 'Peso: de 90,0 kg para 82,0 kg em 74 dias',
  data: DateTime(2026, 11, 6),
  valor: '−8,0 kg',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  for (final escuro in [false, true]) {
    for (final (nomeMarca, marca) in [('teal', _teal), ('limao', _limao)]) {
      final sufixo = '${escuro ? 'escuro' : 'claro'}_$nomeMarca';
      testWidgets('selos 40 e 120 ($sufixo)', (tester) async {
        tester.view.physicalSize = const Size(420, 300) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _tela(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in ConquistaTipo.values) ...[
                      ConquistaSelo(tipo: t),
                      const SizedBox(width: 24),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in ConquistaTipo.values) ...[
                      ConquistaSelo(tipo: t, tamanho: 120, miolo: conquistaNumero('−8,0 kg', marca)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
            escuro: escuro,
            marca: marca,
          ),
        );
        await tester.pumpAndSettle();
        await expectFocuxGolden(find.byType(Column).first, 'goldens/selos_$sufixo.png');
      });
    }
  }

  for (final mostrar in [true, false]) {
    testWidgets('cartão de story (${mostrar ? 'com' : 'sem'} valor)', (tester) async {
      tester.view.physicalSize = const Size(360, 640) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _tela(
          ConquistaCartao(
            conquista: _conquista(ConquistaTipo.meta),
            mostrarValor: mostrar,
            marca: (logoUrl: null, nome: 'Studio Ana'),
          ),
          escuro: false,
          marca: _teal,
        ),
      );
      await tester.pumpAndSettle();
      if (!mostrar) {
        expect(find.textContaining('kg'), findsNothing);
      }
      await expectFocuxGolden(find.byType(ConquistaCartao), 'goldens/cartao_${mostrar ? 'com' : 'sem'}_valor.png');
    });
  }
}
