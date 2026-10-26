import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/l10n/app_localizations.dart';

List<FxWeekDay> _dias() => [
  for (var i = 1; i <= 7; i++)
    FxWeekDay(
      dia: i,
      estado: i == 1
          ? FxWeekDayState.concluido
          : i == 3 || i == 5
          ? FxWeekDayState.treino
          : FxWeekDayState.descanso,
      hoje: i == 3,
      proximo: i == 5,
    ),
];

Future<void> _abrir(WidgetTester tester, List<FxWeekDay> dias, {double escala = 1}) async {
  tester.view
    ..physicalSize = const Size(320, 400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(12), child: FxWeekStrip(dias: dias))),
    ),
  );
}

void main() {
  testWidgets('mostra os sete nomes de dia', (tester) async {
    await _abrir(tester, _dias());
    for (final d in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']) {
      expect(find.text(d), findsOneWidget);
    }
  });

  testWidgets('concluído tem marca e treino tem haltere', (tester) async {
    await _abrir(tester, _dias());
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsNWidgets(2));
  });

  testWidgets('lista vazia não ocupa lugar', (tester) async {
    await _abrir(tester, const []);
    expect(find.text('Seg'), findsNothing);
  });

  testWidgets('texto 2.0 em tela estreita não estoura', (tester) async {
    await _abrir(tester, _dias(), escala: 2);
    expect(tester.takeException(), isNull);
  });

  test('semântica lê estado, hoje e próximo treino', () {
    final s = lookupS(const Locale('pt'));
    final texto = FxWeekStrip.semantica(s, _dias());
    expect(texto, contains('Seg: feito'));
    expect(texto, contains('Qua: treino, Hoje'));
    expect(texto, contains('Sex: treino, Próximo treino'));
    expect(texto, contains('Ter: descanso'));
  });
}
