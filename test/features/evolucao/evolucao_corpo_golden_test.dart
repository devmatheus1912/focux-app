@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/motion_preferences.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_hero.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_medidas_aba.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

MedidaCorporal _medida(int id, String data, double peso, double cintura, double braco) =>
    MedidaCorporal(id: id, data: data, peso: peso, cintura: cintura, braco: braco);

final _medidas = [
  _medida(1, '2026-10-30', 90, 50, 60),
  _medida(2, '2026-11-01', 100, 70, 52),
  _medida(3, '2026-11-02', 110, 70, 55),
];

MetaCorporal _meta(int id, String metrica, double inicio, double alvo, double atual) =>
    MetaCorporal(
      id: id,
      metrica: metrica,
      tipo: 'META',
      valorInicial: inicio,
      valorAlvo: alvo,
      valorAtual: atual,
      progresso: 0,
      status: 'ATIVA',
    );

final _metas = [
  _meta(1, 'CINTURA', 60, 30, 70),
  _meta(2, 'BRACO', 50, 70, 55),
];

Widget _tela(Widget filho, {double escala = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: MediaQuery.withClampedTextScaling(
    minScaleFactor: escala,
    maxScaleFactor: escala,
    child: Scaffold(body: filho),
  ),
);

Widget _corpo() => EvolucaoMedidasAba(
  medidas: _medidas,
  metas: _metas,
  vazioSubtitulo: '',
  onAtualizar: () async {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  void tela(WidgetTester tester, Size tamanho, {double dpr = 2}) {
    tester.view.physicalSize = tamanho * dpr;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }

  testWidgets('aba Corpo: valor no tamanho do título e rumo da meta', (tester) async {
    tela(tester, const Size(390, 1400));
    await tester.pumpWidget(_tela(_corpo()));
    await tester.pumpAndSettle();
    expect(find.text('se afastando da meta'), findsOneWidget);
    expect(find.text('no rumo da meta'), findsOneWidget);
    expect(find.text('+20,0 cm desde 30/10'), findsOneWidget);
    await expectFocuxGolden(find.byType(EvolucaoMedidasAba), 'goldens/corpo_claro.png');
  });

  testWidgets('topo com o nome da meta no anel', (tester) async {
    tela(tester, const Size(390, 220));
    await tester.pumpWidget(
      _tela(
        const Padding(
          padding: EdgeInsets.all(16),
          child: EvolucaoHero(
            aneis: EvolucaoAneis(
              treinoFeitos: 2,
              treinoPrevistos: 5,
              metaProgresso: 25,
              ultimaMedida: '2026-11-02',
            ),
            metaNome: 'Braço',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Meta · Braço'), findsOneWidget);
    await expectFocuxGolden(find.byType(EvolucaoHero), 'goldens/topo_aneis_claro.png');
  });

  for (final largura in [360.0, 390.0]) {
    testWidgets('aba Corpo aguenta ${largura.toInt()} px @ $kAppMaxTextScale', (tester) async {
      tela(tester, Size(largura, 1600), dpr: 1);
      await tester.pumpWidget(_tela(_corpo(), escala: kAppMaxTextScale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
