@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';
import 'package:focux_app/features/avaliacao/data/avaliacao_repository.dart';
import 'package:focux_app/features/avaliacao/widgets/evolucao_comparacao_linhas.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_hero.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_medidas_aba.dart';
import 'package:focux_app/features/exercicios/widgets/add_exercicio_filters_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

MedidaCorporal _medida(int id, String data, double peso, double cintura) =>
    MedidaCorporal.fromJson({
      'id': id,
      'data': data,
      'peso': peso,
      'cintura': cintura,
      'registradoPor': 'PERSONAL',
    });

final _medidas = [
  _medida(1, '2026-10-30', 90, 50),
  _medida(2, '2026-11-01', 100, 70),
  _medida(3, '2026-11-02', 105, 60),
];

Widget _tela(Widget filho, {required bool escuro}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true),
  darkTheme: ThemeData.dark(useMaterial3: true),
  themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: filho)),
);

Future<void> _pronto(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  void tela(WidgetTester tester, Size tamanho) {
    tester.view.physicalSize = tamanho * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  for (final escuro in [false, true]) {
    final sufixo = escuro ? 'escuro' : 'claro';

    testWidgets('gráfico com os 3 registros e o alvo ($sufixo)', (tester) async {
      tela(tester, const Size(390, 300));
      await tester.pumpWidget(
        _tela(
          FxGraficoLinha(
            pontos: serieDaMetrica(_medidas, EvolucaoMetrica.peso),
            unidade: 'kg',
            alvo: 110,
            resumo: 'Peso',
          ),
          escuro: escuro,
        ),
      );
      await _pronto(tester);
      await expectFocuxGolden(find.byType(FxGraficoLinha), 'goldens/grafico_peso_$sufixo.png');
    });

    testWidgets('comparar em lista única ($sufixo)', (tester) async {
      tela(tester, const Size(390, 500));
      const primeira = {
        'avaliadoEm': '2026-10-30',
        'pesoKg': 90.0,
        'cinturaCm': 60.0,
      };
      const atual = {
        'avaliadoEm': '2026-11-02',
        'pesoKg': 105.0,
        'cinturaCm': 60.0,
      };
      await tester.pumpWidget(
        _tela(
          EvolucaoComparacaoLinhas(
            primeira: SnapshotAvaliacao.fromJson(primeira),
            atual: SnapshotAvaliacao.fromJson(atual),
          ),
          escuro: escuro,
        ),
      );
      await _pronto(tester);
      expect(find.text('↑ 15,0 kg'), findsOneWidget);
      expect(find.text('='), findsOneWidget);
      await expectFocuxGolden(find.byType(EvolucaoComparacaoLinhas), 'goldens/comparar_$sufixo.png');
    });

    testWidgets('card de progresso ($sufixo)', (tester) async {
      tela(tester, const Size(390, 160));
      await tester.pumpWidget(
        _tela(
          EvolucaoMiniAneis(
            aneis: const EvolucaoAneis(
              treinoFeitos: 1,
              treinoPrevistos: 5,
              metaProgresso: 50,
              ultimaMedida: '2026-11-02',
            ),
            doPersonal: false,
            onTap: () {},
            pesoLinha: '105,0 kg · +15,0 kg',
          ),
          escuro: escuro,
        ),
      );
      await _pronto(tester);
      await expectFocuxGolden(find.byType(EvolucaoMiniAneis), 'goldens/card_progresso_$sufixo.png');
    });

    testWidgets('folha de histórico ($sufixo)', (tester) async {
      tela(tester, const Size(390, 1200));
      await tester.pumpWidget(
        _tela(
          EvolucaoMedidasAba(
            medidas: _medidas,
            vazioSubtitulo: '',
            onAtualizar: () async {},
            onAbrirMedida: (_) {},
          ),
          escuro: escuro,
        ),
      );
      await _pronto(tester);
      await tester.tap(find.text('Histórico · 3 registros'));
      await _pronto(tester);
      expect(find.text('Histórico'), findsOneWidget);
      await expectFocuxGolden(find.byType(MaterialApp), 'goldens/folha_historico_$sufixo.png');
    });

    testWidgets('folha de equipamentos ($sufixo)', (tester) async {
      tela(tester, const Size(390, 844));
      await tester.pumpWidget(
        _tela(
          Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => showAddExercicioFiltersSheet(
                        context,
                        equipamentos: const {},
                        espacos: const {},
                      ),
                  child: const Text('abrir'),
                ),
          ),
          escuro: escuro,
        ),
      );
      await tester.tap(find.text('abrir'));
      await _pronto(tester);
      expect(find.text('0 equipamentos · 0 espaços'), findsOneWidget);
      await expectFocuxGolden(find.byType(MaterialApp), 'goldens/folha_equipamentos_$sufixo.png');
    });
  }

  testWidgets('folha de equipamentos com teclado em tela pequena não estoura', (
    tester,
  ) async {
    tela(tester, const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      _tela(
        Builder(
          builder:
              (context) => ElevatedButton(
                onPressed:
                    () => showAddExercicioFiltersSheet(
                      context,
                      equipamentos: const {},
                      espacos: const {},
                    ),
                child: const Text('abrir'),
              ),
        ),
        escuro: false,
      ),
    );
    await tester.tap(find.text('abrir'));
    await _pronto(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Equipamentos e espaços'), findsOneWidget);
  });

  testWidgets('barra de composição corporal aparece (não fica com altura 0)', (
    tester,
  ) async {
    tela(tester, const Size(390, 500));
    const snap = {
      'avaliadoEm': '2026-11-02',
      'percGordura': 20.0,
      'percMassa': 80.0,
    };
    await tester.pumpWidget(
      _tela(
        EvolucaoComparacaoLinhas(
          primeira: SnapshotAvaliacao.fromJson(snap),
          atual: SnapshotAvaliacao.fromJson(snap),
        ),
        escuro: false,
      ),
    );
    await _pronto(tester);
    final faixas = find.descendant(
      of: find.byType(EvolucaoComparacaoLinhas),
      matching: find.byType(ColoredBox),
    );
    expect(faixas, findsWidgets);
    for (final faixa in faixas.evaluate()) {
      expect(tester.getSize(find.byWidget(faixa.widget)).height, 12);
    }
  });
}
