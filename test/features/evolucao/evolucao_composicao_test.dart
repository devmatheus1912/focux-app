import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_medidas_aba.dart';
import 'package:focux_app/features/evolucao/widgets/medida_form_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _tela(Widget filho) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: filho),
);

PontoGordura _p(String data, double valor) =>
    (data: data, valor: valor, avaliacaoId: null, conferido: false);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('massa magra é medida da avaliação, com meta MASSA', () {
    expect(EvolucaoMetrica.massa.codigoMeta, 'MASSA');
    expect(EvolucaoMetrica.massa.unidade, '%');
    expect(evolucaoMetricaDaAvaliacao(EvolucaoMetrica.massa), isTrue);
    expect(EvolucaoMetrica.massa.valor(MedidaCorporal(id: 1, data: '2026-11-01', peso: 80)), isNull);
  });

  test('foi e voltou: só com variação no meio', () {
    PontoGrafico p(int dia, double v) => PontoGrafico(DateTime(2026, 11, dia), v);
    expect(serieVoltouAoInicio([p(1, 20), p(4, 15), p(14, 20)]), isTrue);
    expect(serieVoltouAoInicio([p(1, 20), p(4, 20), p(14, 20)]), isFalse);
    expect(serieVoltouAoInicio([p(1, 20), p(14, 20)]), isFalse);
    expect(serieVoltouAoInicio([p(1, 20), p(4, 15), p(14, 18)]), isFalse);
  });

  test('gordura e massa magra somam perto de 100%', () {
    expect(massaMagraPelaGordura(20), 80);
    expect(massaMagraPelaGordura(17.5), 82.5);
    expect(composicaoCoerente(20, 80), isTrue);
    expect(composicaoCoerente(20.5, 79.5), isTrue);
    expect(composicaoCoerente(20, 12), isFalse);
    expect(composicaoCoerente(20, null), isTrue);
    expect(composicaoCoerente(null, 12), isTrue);
  });

  testWidgets('Corpo lista massa magra e diz "Mesmo valor de" quando a gordura voltou', (tester) async {
    tester.view.physicalSize = const Size(390, 1800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _tela(
        EvolucaoMedidasAba(
          medidas: [MedidaCorporal(id: 1, data: '2026-10-30', peso: 90)],
          gordura: [_p('2026-10-30', 20), _p('2026-11-04', 15), _p('2026-11-14', 20)],
          massa: [_p('2026-10-30', 80), _p('2026-11-04', 85), _p('2026-11-14', 80)],
          vazioSubtitulo: '',
          onAtualizar: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Massa magra'), findsOneWidget);
    expect(find.text('Mesmo valor de 30/10'), findsNWidgets(2));
    expect(find.textContaining('Sem mudança'), findsNothing);
  });

  testWidgets('nova medida: a massa magra acompanha a gordura e a soma errada aparece no campo', (tester) async {
    tester.view.physicalSize = const Size(390, 1800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _tela(
        Builder(
          builder:
              (context) => TextButton(
                onPressed: () => novaMedidaSheet(context, medidas: const []),
                child: const Text('abrir'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextField);
    // Peso, cintura, quadril, braço, gordura, massa.
    await tester.enterText(campos.at(4), '20');
    await tester.pump();
    expect(tester.widget<TextField>(campos.at(5)).controller!.text, '80,0');
    await tester.enterText(campos.at(5), '12');
    await tester.pump();
    expect(find.text('Gordura e massa magra devem somar perto de 100%.'), findsOneWidget);
    // Digitada à mão, a massa não segue mais a gordura.
    await tester.enterText(campos.at(4), '25');
    await tester.pump();
    expect(tester.widget<TextField>(campos.at(5)).controller!.text, '12');
  });
}
